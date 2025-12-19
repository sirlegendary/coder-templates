data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "coder_task" "me" {}

data "kubernetes_secret_v1" "openai_api_key" {
  metadata {
    name      = "openai-api-key"
    namespace = var.namespace
  }
}
