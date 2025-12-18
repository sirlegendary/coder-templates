terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of the Coder agent to attach this task to."
}

variable "ollama_model" {
  type        = string
  default     = "llama3.1:8b"
  description = "The Ollama model to use for coding tasks."
}

# Stable Ollama icon from Simple Icons CDN
locals {
  ollama_icon_url = "https://cdn.simpleicons.org/ollama/white" 
}

resource "coder_script" "ollama_setup" {
  agent_id     = var.agent_id
  display_name = "Ollama Coder Setup"
  icon         = local.ollama_icon_url
  run_on_start = true

  script = <<-EOT
    #!/bin/bash
    set -e

    echo "--- Initialising Ollama Coder (UK) ---"

    # Create directories
    mkdir -p "$HOME/.venv"
    mkdir -p "$HOME/.local/bin"

    # 1. Setup Virtual Environment and Aider
    if [ ! -d "$HOME/.venv/aider" ]; then
      python3 -m venv "$HOME/.venv/aider"
    fi
    "$HOME/.venv/aider/bin/pip" install aider-chat --quiet

    # 2. Create a physical script file (Replacing the alias)
    # This ensures the command works for the Dashboard Button and the Terminal
    cat <<EOF > "$HOME/.local/bin/coder-ai"
#!/bin/bash
export OLLAMA_API_BASE="http://host.containers.internal:11434"
exec "$HOME/.venv/aider/bin/aider" --model "ollama_chat/${var.ollama_model}" "\$@"
EOF

    chmod +x "$HOME/.local/bin/coder-ai"

    echo "✅ Script created at ~/.local/bin/coder-ai"
    echo "--- Setup Complete ---"
  EOT
}

resource "coder_app" "aider_terminal" {
  agent_id     = var.agent_id
  slug         = "aider"
  display_name = "AI Chat (Aider)"
  icon         = local.ollama_icon_url
  
  # Use the absolute path to ensure it always finds the command
  command = "bash -c '$HOME/.local/bin/coder-ai'"
}