resource "kubernetes_persistent_volume_claim_v1" "workspaces" {
  metadata {
    name      = "coder-${lower(data.coder_workspace.me.id)}-workspaces"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-${lower(data.coder_workspace.me.id)}-workspaces"
      "app.kubernetes.io/instance" = "coder-${lower(data.coder_workspace.me.id)}-workspaces"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace_owner.me.id
      "com.coder.user.username"  = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${local.workspaces_volume_size}Gi"
      }
    }
  }
}

resource "kubernetes_pod_v1" "dev" {
  count = data.coder_workspace.me.start_count

  metadata {
    name      = local.workspace_name
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = local.workspace_name
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }

    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }

  spec {
    service_account_name = data.coder_workspace.me.name

    security_context {
      run_as_user = 1000
      fs_group    = 1000
    }

    # Docker-in-Docker sidecar container (privileged)
    dynamic "container" {
      for_each = var.use_docker_sidecar ? [1] : []
      content {
        name              = "docker-sidecar"
        image             = local.docker_dind_image
        image_pull_policy = "IfNotPresent"
        security_context {
          privileged  = true
          run_as_user = 0 # Must run as root
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
    container {
      name              = "dev"
      image             = local.devcontainer_builder_image
      image_pull_policy = "IfNotPresent"

      command = ["sh", "-c", coder_agent.main.init_script]

      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }

      # Override Coder URL to use internal service DNS
      env {
        name  = "CODER_URL"
        value = "http://coder.coder.svc.cluster.local"
      }

      # Docker host for sidecar (if enabled)
      dynamic "env" {
        for_each = var.use_docker_sidecar ? [1] : []
        content {
          name  = "DOCKER_HOST"
          value = "localhost:2375"
        }
      }

      resources {
        requests = {
          "cpu"    = "${local.cpu_request}"
          "memory" = "${local.memory_request}Gi"
        }

        limits = {
          "cpu"    = "${local.cpu_limit}"
          "memory" = "${local.memory_limit}Gi"
        }
      }

      volume_mount {
        mount_path = "/workspaces"
        name       = "workspaces"
        read_only  = false
      }
    }

    volume {
      name = "workspaces"

      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim_v1.workspaces.metadata[0].name
        read_only  = false
      }
    }
  }
}
resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  dir  = data.coder_workspace.me.start_count > 0 ? module.git-clone[0].repo_dir : local.repo_base_dir

  # Startup script (conditional based on Sysbox - see locals.tf)
  startup_script = local.startup_script

  env = {
    GIT_AUTHOR_NAME     = local.git_author_name
    GIT_AUTHOR_EMAIL    = local.git_author_email
    GIT_COMMITTER_NAME  = local.git_author_name
    GIT_COMMITTER_EMAIL = local.git_author_email
    # Use internal service URL to avoid TLS issues
    CODER_URL = "http://coder.coder.svc.cluster.local"
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Workspaces Disk"
    key          = "3_workspaces_disk"
    script       = "coder stat disk --path /workspaces"
    interval     = 60
    timeout      = 1
  }
}

module "code-server" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/code-server/coder"

  version = "~> 1.0"

  folder = local.repo_base_dir

  agent_id = coder_agent.main.id
}

resource "coder_script" "configure_bitbucket_ssh" {
  agent_id           = coder_agent.main.id
  display_name       = "Configure Bitbucket SSH"
  run_on_start       = true
  start_blocks_login = true

  script = <<-EOT
    set -e
    echo "Adding Bitbucket to known hosts"
    mkdir -p /home/coder/.ssh
    touch /home/coder/.ssh/known_hosts
    ssh-keyscan -H bitbucket.org > ~/.ssh/known_hosts
  EOT
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "1.0.31"
  agent_id = coder_agent.main.id
}