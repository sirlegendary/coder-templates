module "gemini" {
  source               = "registry.coder.com/coder-labs/gemini/coder"
  version              = "3.0.0"
  agent_id             = coder_agent.main.id
  folder               = local.repo_base_dir
  enable_yolo_mode     = true # Auto-approve all tool calls for automation
  gemini_version       = "preview"
  gemini_settings_json = <<JSON
    {
      "ide": {
        "hasSeenNudge": true
      },
      "security": {
        "auth": {
          "selectedType": "oauth-personal"
        }
      },
      "experimental": {
        "skills": true
      }
    }
  JSON
}

resource "coder_script" "gemini_skills" {
  agent_id           = coder_agent.main.id
  display_name       = "Gemini skills"
  run_on_start       = true
  start_blocks_login = true

  # This multi-line script is executed inside the Coder agent.
  script = <<-EOT
    set -e

    echo "Adding Gemini skills..."
    
    mkdir -p ~/.gemini/skills/frontend-ui-designer
    curl -fsSL https://raw.githubusercontent.com/GrishaAngelovGH/gemini-cli-agent-skills/refs/heads/main/frontend-ui-designer/SKILL.md > ~/.gemini/skills/frontend-ui-designer/SKILL.md
    
  EOT 

  depends_on = [module.gemini]
}
