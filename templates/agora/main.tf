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

data "kubernetes_secret_v1" "coder_ca_source" {
  count = var.coder_ca_secret_name != "" ? 1 : 0

  metadata {
    name      = var.coder_ca_secret_name
    namespace = var.coder_ca_secret_namespace
  }
}

resource "kubernetes_secret_v1" "coder_ca" {
  count = var.coder_ca_secret_name != "" ? 1 : 0

  metadata {
    name      = "coder-ca-${local.workspace_name}"
    namespace = var.namespace
  }

  data = data.kubernetes_secret_v1.coder_ca_source[0].data
  type = data.kubernetes_secret_v1.coder_ca_source[0].type
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

    dynamic "init_container" {
      for_each = var.coder_ca_secret_name != "" ? [1] : []
      content {
        name              = "install-coder-ca"
        image             = local.devcontainer_builder_image
        image_pull_policy = "IfNotPresent"

        security_context {
          run_as_user = 0
        }

        command = ["sh", "-c", <<-EOT
          set -e
          cat /etc/ssl/certs/ca-certificates.crt /mnt/coder-ca/tls.crt > /coder-ca/ca-certificates.crt
        EOT
        ]

        volume_mount {
          mount_path = "/mnt/coder-ca"
          name       = "coder-ca"
          read_only  = true
        }

        volume_mount {
          mount_path = "/coder-ca"
          name       = "coder-ca-bundle"
          read_only  = false
        }
      }
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

        dynamic "volume_mount" {
          for_each = var.coder_ca_secret_name != "" ? [1] : []
          content {
            mount_path = "/coder-ca"
            name       = "coder-ca-bundle"
            read_only  = true
          }
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

      dynamic "env" {
        for_each = var.coder_ca_secret_name != "" ? [1] : []
        content {
          name  = "SSL_CERT_FILE"
          value = "/coder-ca/ca-certificates.crt"
        }
      }

      dynamic "env" {
        for_each = var.coder_ca_secret_name != "" ? [1] : []
        content {
          name  = "NODE_EXTRA_CA_CERTS"
          value = "/coder-ca/ca-certificates.crt"
        }
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

      dynamic "volume_mount" {
        for_each = var.coder_ca_secret_name != "" ? [1] : []
        content {
          mount_path = "/mnt/coder-ca"
          name       = "coder-ca"
          read_only  = true
        }
      }

      dynamic "volume_mount" {
        for_each = var.coder_ca_secret_name != "" ? [1] : []
        content {
          mount_path = "/coder-ca"
          name       = "coder-ca-bundle"
          read_only  = true
        }
      }
    }

    volume {
      name = "workspaces"

      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim_v1.workspaces.metadata[0].name
        read_only  = false
      }
    }

    dynamic "volume" {
      for_each = var.coder_ca_secret_name != "" ? [1] : []
      content {
        name = "coder-ca"
        secret {
          secret_name = kubernetes_secret_v1.coder_ca[0].metadata[0].name
          optional    = false
        }
      }
    }

    dynamic "volume" {
      for_each = var.coder_ca_secret_name != "" ? [1] : []
      content {
        name = "coder-ca-bundle"
        empty_dir {}
      }
    }
  }
}
resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  dir  = local.repo_base_dir

  # Startup script (conditional based on Sysbox - see locals.tf)
  startup_script = local.startup_script

  env = merge(
    {
      GIT_AUTHOR_NAME     = local.git_author_name
      GIT_AUTHOR_EMAIL    = local.git_author_email
      GIT_COMMITTER_NAME  = local.git_author_name
      GIT_COMMITTER_EMAIL = local.git_author_email
      # Use internal service URL to avoid TLS issues
      CODER_URL = "http://coder.coder.svc.cluster.local"
    },
    var.coder_ca_secret_name != "" ? {
      SSL_CERT_FILE       = "/coder-ca/ca-certificates.crt"
      NODE_EXTRA_CA_CERTS = "/coder-ca/ca-certificates.crt"
    } : {}
  )

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

  agent_id   = coder_agent.main.id
  extensions = ["hashicorp.terraform", "hashicorp.hcl"]
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "1.0.31"
  agent_id = coder_agent.main.id
}
