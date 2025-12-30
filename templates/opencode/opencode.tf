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
    "plugin": ["opencode-antigravity-auth@1.2.6"],
    "provider": {
      "google": {
        "models": {
          "gemini-3-flash": {
            "name": "Gemini 3 Flash (Antigravity)",
            "limit": { "context": 1048576, "output": 65536 },
            "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
          },
          "gemini-3-pro-high": {
            "name": "Gemini 3 Pro High (Antigravity)",
            "limit": { "context": 1048576, "output": 65535 },
            "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
          },
          "claude-sonnet-4-5": {
            "name": "Claude Sonnet 4.5 (Antigravity)",
            "limit": { "context": 200000, "output": 64000 },
            "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
          },
          "gpt-oss-120b-medium": {
            "name": "GPT-OSS 120B Medium (Antigravity)",
            "limit": { "context": 131072, "output": 32768 },
            "modalities": { "input": ["text", "image", "pdf"], "output": ["text"] }
          }
        }
      }
    },
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
  })

  pre_install_script = <<-EOT
    #!/bin/bash
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
  EOT
}