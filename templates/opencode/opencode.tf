resource "coder_ai_task" "task" {
  app_id = module.opencode.task_app_id
}

module "opencode" {
  source   = "registry.coder.com/coder-labs/opencode/coder"
  version  = "0.1.1"
  agent_id = coder_agent.main.id
  workdir  = local.repo_base_dir

  ai_prompt = coder_ai_task.task.prompt

  config_json = jsonencode({
    "$schema" = "https://opencode.ai/config.json"
    "plugin": ["opencode-antigravity-auth@1.2.6"]
    mcp = {
      filesystem = {
        command     = ["npx", "-y", "@modelcontextprotocol/server-filesystem", local.repo_base_dir]
        enabled     = true
        type        = "local"
      }
      # gitea = {
      #   url     = "https://gitea-mcp.globallogic.local/api"
      #   enabled = true
      #   type    = "remote"
      #   headers = {
      #     Authorization = "Bearer ${data.kubernetes_secret_v1.gitea_token.data["token"]}"
      #   }
      # }
    }
    # model = "anthropic/claude-sonnet-4-20250514"
  })

  pre_install_script = <<-EOT
    #!/bin/bash
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
  EOT
}