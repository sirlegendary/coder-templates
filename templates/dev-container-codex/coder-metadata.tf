resource "coder_metadata" "container_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = coder_agent.main.id

  item {
    key   = "workspace image"
    value = local.devcontainer_builder_image
  }

  item {
    key   = "git url"
    value = local.repo_url
  }
}
