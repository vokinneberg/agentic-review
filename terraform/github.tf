resource "kubernetes_secret" "github_mcp_token" {
  metadata {
    name      = "github-mcp-token"
    namespace = kubernetes_namespace.kagent.metadata[0].name
  }

  data = {
    token  = var.github_token
    bearer = "Bearer ${var.github_token}"
  }

  depends_on = [kubernetes_namespace.kagent]
}

resource "kubernetes_deployment" "github_mcp" {
  metadata {
    name      = "github-mcp"
    namespace = kubernetes_namespace.kagent.metadata[0].name
    labels = {
      app = "github-mcp"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "github-mcp"
      }
    }

    template {
      metadata {
        labels = {
          app = "github-mcp"
        }
      }

      spec {
        container {
          name  = "github-mcp"
          image = "ghcr.io/github/github-mcp-server:latest"
          args  = ["http", "--toolsets=pull_requests,repos"]

          port {
            container_port = 8082
            protocol       = "TCP"
          }

          env {
            name = "GITHUB_PERSONAL_ACCESS_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.github_mcp_token.metadata[0].name
                key  = "token"
              }
            }
          }

          liveness_probe {
            tcp_socket {
              port = 8082
            }
            initial_delay_seconds = 10
            period_seconds        = 15
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = 8082
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
      }
    }
  }

  depends_on = [kubernetes_namespace.kagent]
}

resource "kubernetes_service" "github_mcp" {
  metadata {
    name      = "github-mcp"
    namespace = kubernetes_namespace.kagent.metadata[0].name
  }

  spec {
    selector = {
      app = "github-mcp"
    }

    port {
      port        = 8082
      target_port = 8082
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "remotemcpserver_github" {
  computed_fields = ["spec"]

  manifest = {
    apiVersion = "kagent.dev/v1alpha2"
    kind       = "RemoteMCPServer"
    metadata = {
      name      = "github"
      namespace = kubernetes_namespace.kagent.metadata[0].name
    }
    spec = {
      description  = "GitHub API: read PRs, files, diffs and post reviews"
      url          = "http://github-mcp:8082/mcp"
      protocol     = "STREAMABLE_HTTP"
      headersFrom = [
        {
          name = "Authorization"
          valueFrom = {
            type = "Secret"
            name = "github-mcp-token"
            key  = "bearer"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_service.github_mcp]
}
