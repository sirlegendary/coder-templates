module "platform-app-templates" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.12"
  agent_id = coder_agent.main.id
  url      = "git@git.globallogic.local:sirlegendary/platform-app-templates.git"
  base_dir = local.repo_base_dir
}

resource "coder_script" "configure_gitea_ssh" {
  agent_id           = coder_agent.main.id
  display_name       = "Configure Gitea SSH"
  run_on_start       = true
  start_blocks_login = true

  script = <<-EOT
    set -e
    echo "Adding Gitea to known hosts"
    mkdir /home/coder/.ssh
    touch /home/coder/.ssh/known_hosts
    ssh-keyscan -H git.globallogic.local > /home/coder/.ssh/known_hosts
  EOT
}

resource "coder_env" "gitea_url" {
  agent_id = coder_agent.main.id
  name     = "GITEA_SERVER_URL"
  value    = "https://gitea.globallogic.local"
}

resource "coder_env" "gitea_token" {
  agent_id = coder_agent.main.id
  name     = "GITEA_TOKEN"
  value    = data.kubernetes_secret_v1.gitea_token.data["token"]
}
