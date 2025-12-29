module "vault_cli" {
  source     = "registry.coder.com/coder/vault-cli/coder"
  version    = "1.1.0"
  agent_id   = coder_agent.main.id
  vault_addr = "https://vault.globallogic.local"
}
