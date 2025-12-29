data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "coder_task" "me" {}

data "coder_parameter" "repo_url" {
  type        = "string"
  name        = "repo_url"
  display_name = "Repo URL"
  default     = "git@git.globallogic.local:sirlegendary/coder-templates.git"
  description = "Repo to clone/build."
  mutable     = true
}

data "kubernetes_secret_v1" "openai_api_key" {
  metadata {
    name      = "openai-api-key"
    namespace = var.namespace
  }
}

data "coder_external_auth" "github" {
  id = "primary-github"
}
