# Devcontainer Setup Guide

This guide explains how to enable Docker-in-Docker support for devcontainers in Coder workspaces running on Kubernetes.

## Overview

Devcontainers require Docker to build and run container-based development environments. In Kubernetes-based Coder workspaces, we use a **privileged Docker-in-Docker (DinD) sidecar** approach to provide Docker daemon access.

## Architecture

```
┌─────────────────────────────────────────────────┐
│ Kubernetes Pod (Workspace)                     │
│                                                 │
│  ┌──────────────────┐    ┌──────────────────┐  │
│  │ docker-sidecar   │    │ dev (main)       │  │
│  │                  │    │                  │  │
│  │ docker:dind      │◄───┤ Docker CLI       │  │
│  │ dockerd          │    │ devcontainer CLI │  │
│  │ :2375            │    │ DOCKER_HOST=     │  │
│  │ (privileged)     │    │ localhost:2375   │  │
│  └──────────────────┘    └──────────────────┘  │
│                                                 │
│  Volume: /workspaces (PVC)                      │
└─────────────────────────────────────────────────┘
```

## Implementation Steps

### 1. Build Custom Docker DinD Image with CA Certificates

To ensure devcontainer agents can communicate with the Coder server over TLS, build a custom Docker DinD image with your internal CA certificates.

**File:** `Docker/docker-dind/Dockerfile` (in k8s-local-platform repository)

```dockerfile
FROM docker:dind

# Add your internal CA bundle
COPY certs/work/globallogic.local/intermediate-ca-bundle.crt /tmp/intermediate-ca-bundle.crt

# Split the bundle into individual certificates and install them
RUN awk 'BEGIN {c=0;} /BEGIN CERT/{c++} { print > "/usr/local/share/ca-certificates/globallogic-ca-" c ".crt"}' /tmp/intermediate-ca-bundle.crt && \
    rm /tmp/intermediate-ca-bundle.crt && \
    update-ca-certificates
```

**Build and load the image:**

```bash
# From k8s-local-platform repository
make work-docker-dind-image
make work-docker-dind-load
```

### 2. Add Docker Sidecar Container

The sidecar runs a privileged Docker daemon that the main container connects to via TCP.

**File:** `main.tf`

```hcl
# Docker-in-Docker sidecar container (privileged)
dynamic "container" {
  for_each = var.use_docker_sidecar ? [1] : []
  content {
    name              = "docker-sidecar"
    image             = local.docker_dind_image
    image_pull_policy = "IfNotPresent"
    security_context {
      privileged   = true
      run_as_user  = 0  # Must run as root
    }
    command = ["dockerd", "-H", "tcp://127.0.0.1:2375"]
    
    # Mount workspaces volume so Docker can bind mount it into devcontainers
    volume_mount {
      mount_path = "/workspaces"
      name       = "workspaces"
      read_only  = false
    }
  }
}
```

**File:** `locals.tf`

```hcl
locals {
  docker_dind_image = "localhost/docker-dind-globallogic:latest"
  # ...
}
```

**Key points:**
- Uses custom image with CA certificates (`local.docker_dind_image`)
- `privileged = true` - Required for Docker daemon to manage containers
- `run_as_user = 0` - Docker daemon must run as root
- `tcp://127.0.0.1:2375` - Exposes Docker API on localhost (shared pod network)
- Mounts `/workspaces` volume for devcontainer bind mounts

### 3. Configure Main Container to Use Sidecar

Set the `DOCKER_HOST` environment variable to point to the sidecar.

**File:** `main.tf`

```hcl
container {
  name  = "dev"
  image = local.devcontainer_builder_image
  
  # Docker host for sidecar (if enabled)
  dynamic "env" {
    for_each = var.use_docker_sidecar ? [1] : []
    content {
      name  = "DOCKER_HOST"
      value = "localhost:2375"
    }
  }
  
  # ... other config
}
```

### 4. Configure Git Clone to Use Persistent Volume

The devcontainer needs to bind mount the repository directory, so it must be on the persistent volume.

**File:** `locals.tf`

```hcl
locals {
  repo_base_dir = "/workspaces"  # Must match PVC mount point
  # ...
}
```

**File:** `git.tf`

```hcl
module "git-clone" {
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.12"
  agent_id = coder_agent.main.id
  url      = local.repo_url
  base_dir = local.repo_base_dir  # Clone to /workspaces
}
```

**File:** `main.tf` (PVC mount)

```hcl
container {
  # ...
  volume_mount {
    mount_path = "/workspaces"
    name       = "workspaces"
    read_only  = false
  }
}
```

### 4. Enable Devcontainer Resource

**File:** `devcontainer.tf`

```hcl
module "devcontainers-cli" {
  source   = "registry.coder.com/coder/devcontainers-cli/coder"
  version  = "1.0.32"
  agent_id = coder_agent.main.id
}

resource "coder_devcontainer" "coder" {
  agent_id         = coder_agent.main.id
  workspace_folder = data.coder_workspace.me.start_count > 0 ? module.git-clone[0].repo_dir : local.repo_base_dir
}
```

### 5. Add Variable to Control Docker Sidecar

**File:** `variables.tf`

```hcl
variable "use_docker_sidecar" {
  type        = bool
  default     = true
  description = <<-EOF
    Enable Docker-in-Docker via privileged sidecar container?
    
    When enabled, adds a docker:dind sidecar to provide Docker daemon.
    Set to false to disable Docker support.
  EOF
}
```

## Why This Approach?

### Alternative: Sysbox Runtime

We initially considered using Sysbox, which allows unprivileged containers to run Docker. However:

- ❌ **Complex installation** - Requires Sysbox runtime on all Kubernetes nodes
- ❌ **Kind compatibility** - Difficult to install on Kind (containerised nodes)
- ❌ **Maintenance overhead** - Additional infrastructure to manage

### Chosen: Privileged Sidecar

- ✅ **Simple setup** - No special runtime required
- ✅ **Works on Kind** - Compatible with local development clusters
- ✅ **Standard Kubernetes** - Uses built-in privileged container support
- ✅ **Isolated** - Docker daemon runs in separate container

## Troubleshooting

### Issue: "Cannot connect to the Docker daemon at tcp://localhost:2375"

**Cause:** Docker sidecar failed to start or is not running as root.

**Solution:**
```bash
# Check sidecar logs
kubectl logs -n coder <workspace-pod> -c docker-sidecar

# Verify sidecar has run_as_user = 0
kubectl get pod -n coder <workspace-pod> -o yaml | grep -A 5 docker-sidecar
```

### Issue: "bind source path does not exist: /home/coder/..."

**Cause:** Git clone is using wrong base directory (not on PVC).

**Solution:**
- Ensure `local.repo_base_dir = "/workspaces"`
- Ensure `git-clone` module has `base_dir = local.repo_base_dir`
- Delete and recreate workspace to re-clone to correct location

### Issue: "dockerd needs to be started with root privileges"

**Cause:** Sidecar container security context missing `run_as_user = 0`.

**Solution:**
```hcl
security_context {
  privileged   = true
  run_as_user  = 0  # Add this
}
```

## Verification

After workspace starts, verify Docker is working:

```bash
# Check Docker connection
docker info

# Verify daemon is accessible
docker ps

# Test with hello-world
docker run hello-world

# Check devcontainer builds
cd /workspaces/<repo-name>
devcontainer build .
```

## Security Considerations

### Privileged Containers

The Docker sidecar runs as a **privileged container**, which has elevated permissions:

- Can access host devices
- Can modify kernel parameters
- Has full container runtime access

**Mitigation:**
- Sidecar is isolated from main workspace container
- Only runs Docker daemon, no user code
- Limited to pod network namespace
- PodSecurityPolicy/PodSecurityStandard can restrict which users can create workspaces

### Network Exposure

Docker daemon listens on `tcp://127.0.0.1:2375` (localhost only):

- ✅ Not exposed outside the pod
- ✅ No TLS required (localhost traffic)
- ✅ Only accessible to containers in same pod

## References

- [Coder: Docker in Workspaces](https://coder.com/docs/admin/templates/extending-templates/docker-in-workspaces)
- [Coder: Git Clone Module](https://registry.coder.com/modules/coder/git-clone)
- [Docker: Docker-in-Docker](https://hub.docker.com/_/docker)
- [Kubernetes: Privileged Containers](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

## Template Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `use_docker_sidecar` | `true` | Enable Docker-in-Docker sidecar for devcontainer support |
| `namespace` | `coder` | Kubernetes namespace for workspaces |
| `use_kubeconfig` | `false` | Use host kubeconfig (true) or in-cluster auth (false) |

## File Structure

```
kubernetes-devcontainer/
├── main.tf              # Pod spec with sidecar and main container
├── git.tf               # Git clone configuration
├── devcontainer.tf      # Devcontainer resource
├── locals.tf            # Local variables (repo_base_dir)
├── variables.tf         # Input variables
├── vault.tf             # Vault integration
├── coder-metadata.tf    # Workspace metadata
└── DEVCONTAINER_SETUP.md # This file
```

## Quick Start

1. **Push template:**
   ```bash
   cd kubernetes-devcontainer
   coder templates push
   ```

2. **Create workspace:**
   ```bash
   coder create my-workspace --template kubernetes-devcontainer
   ```

3. **Verify Docker:**
   ```bash
   coder ssh my-workspace
   docker info
   ```

4. **Devcontainer will auto-build** when you open the workspace in VS Code with the Dev Containers extension.

## Changelog

### 2025-12-09 - Initial Implementation
- Added privileged Docker sidecar approach
- Configured git-clone to use `/workspaces` base directory
- Set `DOCKER_HOST=localhost:2375` for main container
- Removed Sysbox runtime dependency
- Documented security considerations and troubleshooting
