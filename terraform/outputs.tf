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

output "agentgateway_endpoint" {
  description = "Public IP of the agentgateway LoadBalancer (DigitalOcean cloud LB)"
  value       = kubernetes_service.agentgateway.status[0].load_balancer[0].ingress[0].ip
}
