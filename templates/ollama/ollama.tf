module "ollama_coder" {
  source   = "./modules/ollama-tasks"
  agent_id = coder_agent.main.id
#   ollama_model    = "granite-code:20b" 
}