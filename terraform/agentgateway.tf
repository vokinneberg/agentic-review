resource "kubernetes_config_map" "agentgateway_config" {
  metadata {
    name      = "agentgateway-config"
    namespace = kubernetes_namespace.kagent.metadata[0].name
  }

  data = {
    "config.yaml" = <<-EOT
      binds:
      - port: 8080
        listeners:
        - routes:
          - policies:
              a2a: {}
              apiKey:
                mode: strict
                keys:
                  - key: "${var.agentgateway_api_key}"
            backends:
            - host: code-review-agent:8080
    EOT
  }

  depends_on = [kubernetes_namespace.kagent]
}

resource "kubernetes_deployment" "agentgateway" {
  metadata {
    name      = "agentgateway"
    namespace = kubernetes_namespace.kagent.metadata[0].name
    labels = {
      app = "agentgateway"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "agentgateway"
      }
    }

    template {
      metadata {
        labels = {
          app = "agentgateway"
        }
      }

      spec {
        container {
          name  = "agentgateway"
          image = "ghcr.io/agentgateway/agentgateway:latest"
          args  = ["-f", "/etc/agentgateway/config.yaml"]

          port {
            container_port = 8080
            protocol       = "TCP"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/agentgateway"
            read_only  = true
          }

          liveness_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 15
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            failure_threshold     = 3
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.agentgateway_config.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.kagent,
    kubernetes_config_map.agentgateway_config,
    helm_release.kagent,
  ]
}

resource "digitalocean_reserved_ip" "agentgateway" {
  region = var.region
}

resource "kubernetes_service" "agentgateway" {
  metadata {
    name      = "agentgateway"
    namespace = kubernetes_namespace.kagent.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/do-loadbalancer-reserved-ip" = digitalocean_reserved_ip.agentgateway.ip_address
    }
  }

  spec {
    selector = {
      app = "agentgateway"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment.agentgateway]
}
