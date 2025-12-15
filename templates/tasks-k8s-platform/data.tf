data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "coder_parameter" "repo_url" {
  type        = "string"
  name        = "Repo URL"
  default     = "https://github.com/Indexfeed/demo-flask-devcontainer"
  description = "Repo to clone/build."
  mutable     = true
}

data "kubernetes_secret_v1" "openai_api_key" {
  metadata {
    name      = "openai-api-key"
    namespace = var.namespace
  }
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  default     = "Summarise the code in this directory."
  description = "Initial prompt for the Codex CLI"
  mutable     = true
}

data "coder_external_auth" "github" {
  id = "primary-github"
}