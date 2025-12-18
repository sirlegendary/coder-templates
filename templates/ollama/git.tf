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

module "git-clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.12"
  agent_id = coder_agent.main.id
  url      = local.repo_url
  base_dir = local.repo_base_dir
}