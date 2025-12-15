module "devcontainers-cli" {
  source   = "registry.coder.com/coder/devcontainers-cli/coder"
  version  = "1.0.32"
  agent_id = coder_agent.main.id
}

// resource "coder_devcontainer" "coder" {
//   agent_id         = coder_agent.main.id
//   workspace_folder = data.coder_workspace.me.start_count > 0 ? module.git-clone[0].repo_dir : local.repo_base_dir
// }