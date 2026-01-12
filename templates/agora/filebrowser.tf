module "filebrowser" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/filebrowser/coder"
  version  = "1.1.4"
  agent_id = coder_agent.main.id
  folder   = "/"
}
