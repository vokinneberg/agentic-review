variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "homelab"
}

variable "node_size" {
  description = "DigitalOcean Droplet size for worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of worker nodes in the default node pool"
  type        = number
  default     = 2
}

variable "kagent_anthropic_api_key" {
  description = "Anthropic API key used by kagent for LLM inference"
  type        = string
  sensitive   = true
}

variable "ghcr_token" {
  description = "GitHub PAT with read:packages scope for pulling images from GHCR"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub PAT with repo and pull_requests scopes for the GitHub MCP server"
  type        = string
  sensitive   = true
}

variable "diff_tools_image" {
  description = "Container image for the diff-tools MCP server"
  type        = string
  default     = "ghcr.io/vokinneberg/homelab-diff-tools:latest"
}
