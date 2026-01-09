resource "coder_script" "configure_bitbucket_ssh" {
  agent_id           = coder_agent.main.id
  display_name       = "Configure Bitbucket SSH"
  run_on_start       = true
  start_blocks_login = true

  script = <<-EOT
    set -e
    echo "Adding Bitbucket to known hosts"
    mkdir /home/coder/.ssh
    touch /home/coder/.ssh/known_hosts
    ssh-keyscan -H bitbucket.org > ~/.ssh/known_hosts
  EOT
}

module "agora-apps" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.12"
  agent_id = coder_agent.main.id
  url      = "git@bitbucket.org:ecs-group/agora-apps.git"
  base_dir = local.repo_base_dir

  depends_on = [coder_script.configure_bitbucket_ssh]
}

module "agora-base" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.12"
  agent_id = coder_agent.main.id
  url      = "git@bitbucket.org:ecs-group/agora-base.git"
  base_dir = local.repo_base_dir

  depends_on = [coder_script.configure_bitbucket_ssh]
}

module "agent-share" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.12"
  agent_id = coder_agent.main.id
  url      = "git@bitbucket.org:ecs-group/agent-share.git"
  base_dir = local.repo_base_dir

  depends_on = [coder_script.configure_bitbucket_ssh]
}

module "coder-templates" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.12"
  agent_id = coder_agent.main.id
  url      = "git@bitbucket.org:ecs-group/coder-templates.git"
  base_dir = local.repo_base_dir

  depends_on = [coder_script.configure_bitbucket_ssh]
}
