data "helm_template" "metrics_server" {
  name      = "metrics-server"
  namespace = "kube-system"

  repository   = var.metrics_server_helm_repository
  chart        = var.metrics_server_helm_chart
  version      = var.metrics_server_helm_version
  kube_version = var.kubernetes_version

  set {
    name  = "podDisruptionBudget.enabled"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1
  }
  set {
    name  = "podDisruptionBudget.minAvailable"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 1 : 0
  }
  set {
    name  = "replicas"
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > 1 ? 2 : 1
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
    name  = "topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/instance"
    value = "metrics-server"
  }
  set {
    name  = "topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/name"
    value = "metrics-server"
  }

  values = [
    yamlencode(var.metrics_server_helm_values)
  ]
}

locals {
  metrics_server_manifest = {
    name     = "metrics-server"
    contents = data.helm_template.metrics_server.manifest
  }
}
