resource "helm_release" "kagent_crds" {
  name      = "kagent-crds"
  chart     = "oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds"
  namespace = kubernetes_namespace.kagent.metadata[0].name

  depends_on = [kubernetes_namespace.kagent]
}

resource "helm_release" "kagent" {
  name      = "kagent"
  chart     = "oci://ghcr.io/kagent-dev/kagent/helm/kagent"
  namespace = kubernetes_namespace.kagent.metadata[0].name

  set {
    name  = "providers.default"
    value = "anthropic"
  }

  set {
    name  = "providers.anthropic.model"
    value = "claude-sonnet-4-6"
  }

  set_sensitive {
    name  = "providers.anthropic.apiKey"
    value = var.kagent_anthropic_api_key
  }

  depends_on = [helm_release.kagent_crds]
}
