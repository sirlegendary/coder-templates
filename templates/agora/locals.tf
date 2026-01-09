locals {
  workspace_name             = lower(data.coder_workspace.me.name)
  devcontainer_builder_image = "localhost/coder-enterprise-node-lab:latest"
  docker_dind_image          = "localhost/docker-dind-globallogic:latest"

  // Rersource
  cpu_request            = "500m"
  memory_request         = "1"
  cpu_limit              = "1"
  memory_limit           = "2"
  workspaces_volume_size = "10"

  // Git Locals
  git_author_name  = "Wale Salami"
  git_author_email = "wale.salami@globallogic.com"
  bitbucket_email  = local.git_author_email
  # repo_url         = data.coder_parameter.repo_url.value
  repo_base_dir = "/workspaces"

  // Startup script - Docker sidecar sets DOCKER_HOST automatically
  startup_script = <<-EOT
    #!/bin/sh
    echo "Workspace started"
    if [ -n "$DOCKER_HOST" ]; then
      echo "Docker available via sidecar at $DOCKER_HOST"
    else
      echo "Docker not available (sidecar disabled)"
    fi
  EOT
}
