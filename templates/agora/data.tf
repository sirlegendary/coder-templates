data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "coder_task" "me" {}

data "kubernetes_secret_v1" "bitbucket_token" {
  metadata {
    name      = "bitbucket-token"
    namespace = var.namespace
  }
}

