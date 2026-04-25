resource "kubernetes_secret" "ghcr_pull_secret" {
  metadata {
    name      = "ghcr-pull-secret"
    namespace = kubernetes_namespace.kagent.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = "vokinneberg"
          password = var.ghcr_token
          auth     = base64encode("vokinneberg:${var.ghcr_token}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.kagent]
}

resource "kubectl_manifest" "mcpserver_diff_tools" {
  yaml_body = yamlencode({
    apiVersion = "kagent.dev/v1alpha1"
    kind       = "MCPServer"
    metadata = {
      name      = "diff-tools"
      namespace = kubernetes_namespace.kagent.metadata[0].name
    }
    spec = {
      transportType = "http"
      deployment = {
        image = var.diff_tools_image
        port  = 8000
        imagePullSecrets = [
          { name = kubernetes_secret.ghcr_pull_secret.metadata[0].name }
        ]
        resources = {
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
      httpTransport = {
        targetPort = 8000
      }
    }
  })

  depends_on = [helm_release.kagent_crds, kubernetes_namespace.kagent, kubernetes_secret.ghcr_pull_secret]
}

resource "kubectl_manifest" "remotemcpserver_diff_tools" {
  yaml_body = yamlencode({
    apiVersion = "kagent.dev/v1alpha2"
    kind       = "RemoteMCPServer"
    metadata = {
      name      = "diff-tools"
      namespace = kubernetes_namespace.kagent.metadata[0].name
    }
    spec = {
      description = "Deterministic diff preprocessing: github_diff_parser and code_chunker"
      url         = "http://diff-tools:8000/mcp"
      protocol    = "STREAMABLE_HTTP"
    }
  })

  depends_on = [kubectl_manifest.mcpserver_diff_tools]
}
