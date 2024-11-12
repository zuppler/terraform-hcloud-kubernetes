locals {
  cert_manager_namespace = var.cert_manager_enabled ? {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = data.helm_template.cert_manager[0].namespace
    }
  } : null
}

data "helm_template" "cert_manager" {
  count = var.cert_manager_enabled ? 1 : 0

  name      = "cert-manager"
  namespace = "cert-manager"

  repository   = var.cert_manager_helm_repository
  chart        = var.cert_manager_helm_chart
  version      = var.cert_manager_helm_version
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

  values = [
    yamlencode(var.cert_manager_helm_values)
  ]
}

locals {
  cert_manager_manifest = var.cert_manager_enabled ? {
    name     = "cert-manager"
    contents = <<-EOF
      ${yamlencode(local.cert_manager_namespace)}
      ---
      ${data.helm_template.cert_manager[0].manifest}
    EOF
  } : null
}
