locals {
  cert_manager_namespace = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = data.helm_template.cert_manager.namespace
    }
  }
}

data "helm_template" "cert_manager" {
  name      = "cert-manager"
  namespace = "cert-manager"

  repository   = "https://charts.jetstack.io"
  chart        = "cert-manager"
  version      = var.cert_manager_version
  kube_version = var.kubernetes_version

  set {
    name  = "crds.enabled"
    value = true
  }
  set {
    name  = "startupapicheck.enabled"
    value = false
  }

  set {
    name  = "replicaCount"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 2 : 1
  }
  set {
    name  = "webhook.replicaCount"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 2 : 1
  }
  set {
    name  = "cainjector.replicaCount"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 2 : 1
  }

  set {
    name  = "podDisruptionBudget.enabled"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1
  }
  set {
    name  = "podDisruptionBudget.minAvailable"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 1 : 0
  }
  set {
    name  = "webhook.podDisruptionBudget.enabled"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1
  }
  set {
    name  = "webhook.podDisruptionBudget.minAvailable"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 1 : 0
  }
  set {
    name  = "cainjector.podDisruptionBudget.enabled"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1
  }
  set {
    name  = "cainjector.podDisruptionBudget.minAvailable"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 1 : 0
  }

  set {
    name  = "topologySpreadConstraints[0].topologyKey"
    value = "kubernetes.io/hostname"
  }
  set {
    name  = "topologySpreadConstraints[0].maxSkew"
    value = 1
  }
  set {
    name  = "topologySpreadConstraints[0].whenUnsatisfiable"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 2 ? "DoNotSchedule" : "ScheduleAnyway"
  }
  set {
    name  = "topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/component"
    value = "controller"
  }
  set {
    name  = "topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/instance"
    value = "cert-manager"
  }
  set {
    name  = "topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/name"
    value = "cert-manager"
  }

  set {
    name  = "webhook.topologySpreadConstraints[0].topologyKey"
    value = "kubernetes.io/hostname"
  }
  set {
    name  = "webhook.topologySpreadConstraints[0].maxSkew"
    value = 1
  }
  set {
    name  = "webhook.topologySpreadConstraints[0].whenUnsatisfiable"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 2 ? "DoNotSchedule" : "ScheduleAnyway"
  }
  set {
    name  = "webhook.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/component"
    value = "webhook"
  }
  set {
    name  = "webhook.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/instance"
    value = "cert-manager"
  }
  set {
    name  = "webhook.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/name"
    value = "webhook"
  }

  set {
    name  = "cainjector.topologySpreadConstraints[0].topologyKey"
    value = "kubernetes.io/hostname"
  }
  set {
    name  = "cainjector.topologySpreadConstraints[0].maxSkew"
    value = 1
  }
  set {
    name  = "cainjector.topologySpreadConstraints[0].whenUnsatisfiable"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 2 ? "DoNotSchedule" : "ScheduleAnyway"
  }
  set {
    name  = "cainjector.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/component"
    value = "cainjector"
  }
  set {
    name  = "cainjector.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/instance"
    value = "cert-manager"
  }
  set {
    name  = "cainjector.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/name"
    value = "cainjector"
  }
}

locals {
  cert_manager_manifest = {
    name     = "cert-manager"
    contents = <<-EOF
      ${yamlencode(local.cert_manager_namespace)}
      ---
      ${data.helm_template.cert_manager.manifest}
    EOF
  }
}
