module "devcontainers-cli" {
  source   = "registry.coder.com/coder/devcontainers-cli/coder"
  version  = "1.0.32"
  agent_id = coder_agent.main.id
}
