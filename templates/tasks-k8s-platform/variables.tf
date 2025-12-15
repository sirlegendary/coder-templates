variable "use_kubeconfig" {
  type        = bool
  default     = false
  description = <<-EOF
    Use host kubeconfig?

    true  – Coder host outside the cluster  
    false – Coder running inside the cluster
  EOF
}

variable "namespace" {
  type        = string
  default     = "coder"
  description = "Namespace for workspaces."
}

variable "use_docker_sidecar" {
  type        = bool
  default     = true
  description = <<-EOF
    Enable Docker-in-Docker via privileged sidecar container?
    
    When enabled, adds a docker:dind sidecar to provide Docker daemon.
    Set to false to disable Docker support.
  EOF
}
