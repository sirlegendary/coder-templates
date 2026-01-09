resource "coder_env" "bitbucket_token" {
  agent_id = coder_agent.main.id
  name     = "BITBUCKET_TOKEN"
  value    = data.kubernetes_secret_v1.bitbucket_token.data["token"]
}

resource "coder_env" "bitbucket_email" {
  agent_id = coder_agent.main.id
  name     = "BITBUCKET_EMAIL"
  value    = local.bitbucket_email
}

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

resource "coder_script" "clone_bitbucket_repos" {
  agent_id           = coder_agent.main.id
  display_name       = "Clone Bitbucket repos"
  run_on_start       = true
  start_blocks_login = true

  # This multi-line script is executed inside the Coder agent.
  script = <<-EOT
    set -e

    echo "Waiting for 5 seconds..."
    sleep 5

    echo "Cloning Bitbucket repos..."
    cd /workspaces
    git clone git@bitbucket.org:ecs-group/agora-apps.git
    git clone git@bitbucket.org:ecs-group/agora-base.git
    git clone git@bitbucket.org:ecs-group/agent-share.git
    git clone git@bitbucket.org:ecs-group/coder-templates.git
  EOT

  depends_on = [coder_script.configure_bitbucket_ssh]
}

# module "agora-apps" {
#   count    = data.coder_workspace.me.start_count
#   source   = "registry.coder.com/modules/git-clone/coder"
#   version  = "1.0.12"
#   agent_id = coder_agent.main.id
#   url      = "git@bitbucket.org:ecs-group/agora-apps.git"
#   base_dir = local.repo_base_dir

#   depends_on = [coder_script.configure_bitbucket_ssh]
# }

# module "agora-base" {
#   count    = data.coder_workspace.me.start_count
#   source   = "registry.coder.com/modules/git-clone/coder"
#   version  = "1.0.12"
#   agent_id = coder_agent.main.id
#   url      = "git@bitbucket.org:ecs-group/agora-base.git"
#   base_dir = local.repo_base_dir

#   depends_on = [coder_script.configure_bitbucket_ssh]
# }

# module "agent-share" {
#   count    = data.coder_workspace.me.start_count
#   source   = "registry.coder.com/modules/git-clone/coder"
#   version  = "1.0.12"
#   agent_id = coder_agent.main.id
#   url      = "git@bitbucket.org:ecs-group/agent-share.git"
#   base_dir = local.repo_base_dir

#   depends_on = [coder_script.configure_bitbucket_ssh]
# }

# module "coder-templates" {
#   count    = data.coder_workspace.me.start_count
#   source   = "registry.coder.com/modules/git-clone/coder"
#   version  = "1.0.12"
#   agent_id = coder_agent.main.id
#   url      = "git@bitbucket.org:ecs-group/coder-templates.git"
#   base_dir = local.repo_base_dir

#   depends_on = [coder_script.configure_bitbucket_ssh]
# }
