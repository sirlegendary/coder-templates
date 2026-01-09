module "gemini" {
  source           = "registry.coder.com/coder-labs/gemini/coder"
  version          = "3.0.0"
  agent_id         = coder_agent.main.id
  folder           = local.repo_base_dir
  enable_yolo_mode = true # Auto-approve all tool calls for automation
  gemini_version   = "preview"
}
