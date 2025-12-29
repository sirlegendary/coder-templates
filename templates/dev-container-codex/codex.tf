module "codex" {
  source         = "registry.coder.com/coder-labs/codex/coder"
  version        = "3.1.1"
  agent_id       = coder_agent.main.id
  openai_api_key = data.kubernetes_secret_v1.openai_api_key.data["api-key"]
  codex_model    = "gpt-5-mini"
  ai_prompt      = data.coder_task.me.prompt 
  workdir        = local.repo_base_dir

  # Custom configuration for full auto mode
  base_config_toml = <<-EOT
    approval_policy = "on-request"
    network_access = "enabled"
    sandbox_mode = "workspace-write"
    preferred_auth_method = "apikey"
  EOT
}