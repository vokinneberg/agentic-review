output "cluster_endpoint" {
  description = "DOKS API server endpoint"
  value       = digitalocean_kubernetes_cluster.homelab.endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Raw kubeconfig for the homelab cluster"
  value       = digitalocean_kubernetes_cluster.homelab.kube_config[0].raw_config
  sensitive   = true
}

output "cluster_id" {
  description = "DigitalOcean Kubernetes cluster ID"
  value       = digitalocean_kubernetes_cluster.homelab.id
}

output "agentgateway_ip" {
  description = "Reserved IP assigned to the agentgateway LoadBalancer"
  value       = digitalocean_reserved_ip.agentgateway.ip_address
}

output "agentgateway_endpoint" {
  description = "Public endpoint of the agentgateway"
  value       = "http://${digitalocean_reserved_ip.agentgateway.ip_address}"
}
