resource "digitalocean_kubernetes_cluster" "homelab" {
  name    = var.cluster_name
  region  = var.region
  version = "1.35.1-do.2"

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count

    labels = {
      managed-by = "terraform"
    }
  }
}
