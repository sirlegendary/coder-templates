---
display_name: Kubernetes (Devcontainer)
description: Provision envbuilder pods as Coder workspaces
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [container, kubernetes, devcontainer]
---

# Remote Development on Kubernetes Pods (with Devcontainers)

Provision Devcontainers as [Coder workspaces](https://coder.com/docs/workspaces) on Kubernetes with this example template.

## Prerequisites

### Infrastructure

**Cluster**: This template requires an existing Kubernetes cluster.

**Container Image**: This template uses the [envbuilder image](https://github.com/coder/envbuilder) to build a Devcontainer from a `devcontainer.json`.

**(Optional) Cache Registry**: Envbuilder can utilize a Docker registry as a cache to speed up workspace builds. The [envbuilder Terraform provider](https://github.com/coder/terraform-provider-envbuilder) will check the contents of the cache to determine if a prebuilt image exists. In the case of some missing layers in the registry (partial cache miss), Envbuilder can still utilize some of the build cache from the registry.

### Authentication

This template authenticates using a `~/.kube/config`, if present on the server, or via built-in authentication if the Coder provisioner is running on Kubernetes with an authorized ServiceAccount. To use another [authentication method](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#authentication), edit the template.

## Architecture
  
This template uses a **Docker-in-Docker (DinD) sidecar** approach to provide Docker daemon access for building and running devcontainers. See [DEVCONTAINER_SETUP.md](./DEVCONTAINER_SETUP.md) for detailed implementation guide.

This template provisions the following resources:

- Kubernetes pod with two containers:
  - **docker-sidecar**: Privileged container running Docker daemon with custom CA certificates
  - **dev**: Main workspace container with Docker CLI and devcontainer CLI
- Kubernetes persistent volume claim (persistent on `/workspaces`)
- Service account for workspace pod

This template will fetch a Git repo containing a `devcontainer.json` specified by the `repo` parameter, and builds it
with [`envbuilder`](https://github.com/coder/envbuilder).
The Git repository is cloned inside the `/workspaces` volume if not present.
Any local changes to the Devcontainer files inside the volume will be applied when you restart the workspace.
As you might suspect, any tools or files outside of `/workspaces` or not added as part of the Devcontainer specification are not persisted.
Edit the `devcontainer.json` instead!
 
> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.

## Docker-in-Docker Setup

This template uses a privileged Docker sidecar to enable devcontainer support. Key features:

- **Automatic**: Docker daemon starts automatically in sidecar container
- **Isolated**: Daemon runs in separate container from workspace
- **Persistent storage**: Repositories cloned to `/workspaces` PVC
- **Secure**: Docker API only accessible within pod (localhost)
- **Custom CA certificates**: Docker sidecar includes internal CA certificates for TLS verification

For detailed setup, troubleshooting, and security considerations, see [DEVCONTAINER_SETUP.md](./DEVCONTAINER_SETUP.md).

### Custom Docker DinD Image

This template uses a custom Docker DinD image (`docker-dind-globallogic:latest`) that includes internal CA certificates. This ensures devcontainer agents can communicate with the Coder server over TLS.

**Building the custom image:**

```bash
# From the k8s-local-platform repository
make work-docker-dind-image
make work-docker-dind-load
```

The custom image is built from `Docker/docker-dind/Dockerfile` and includes your organisation's CA certificate bundle.

### Disabling Docker Sidecar

To disable Docker support, set the template variable:

```bash
coder create my-workspace --template kubernetes-devcontainer --parameter use_docker_sidecar=false
```

## Template Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `use_docker_sidecar` | `true` | Enable Docker-in-Docker sidecar for devcontainer support |
| `namespace` | `coder` | Kubernetes namespace for workspaces |
| `use_kubeconfig` | `false` | Use host kubeconfig (true) or in-cluster auth (false) |

## Custom Images

This template uses custom images with internal CA certificates:

- **Workspace image**: `localhost/coder-enterprise-node-globallogic:latest`
- **Docker DinD image**: `localhost/docker-dind-globallogic:latest`

Both images must be built and loaded into your Kubernetes cluster before creating workspaces. See the `k8s-local-platform` repository Makefile for build targets.