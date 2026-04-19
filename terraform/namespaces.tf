resource "kubernetes_namespace" "kagent" {
  metadata {
    name = "kagent"
  }

  depends_on = [digitalocean_kubernetes_cluster.homelab]
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
  }

  depends_on = [digitalocean_kubernetes_cluster.homelab]
}
