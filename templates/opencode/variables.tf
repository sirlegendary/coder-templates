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

variable "coder_ca_secret_name" {
  type        = string
  default     = "offline-intermediate-ca-globallogic-local"
  description = "Optional: name of a Kubernetes Secret containing a CA bundle to trust (e.g., to trust your internal Coder TLS cert)."
}

variable "coder_ca_secret_namespace" {
  type        = string
  default     = "cert-manager"
  description = "Namespace of the CA bundle secret (if coder_ca_secret_name is set)."
}

variable "gitea_registry_host" {
  type        = string
  default     = "gitea.globallogic.local"
  description = "Host for the Gitea container registry."
}

variable "git_url" {
  type        = string
  default     = "git@git.globallogic.local"
  description = "URL to the Gitea instance."
}

variable "gitea_demo_org" {
  type        = string
  default     = "sirlegendary"
  description = "Gitea demo organisation."
}
