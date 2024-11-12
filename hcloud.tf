# Hcloud Secret
locals {
  hcloud_secret_manifest = {
    name = "hcloud-secret"
    contents = yamlencode({
      apiVersion = "v1"
      kind       = "Secret"
      type       = "Opaque"
      metadata = {
        name      = "hcloud"
        namespace = "kube-system"
      }
      data = {
        network = base64encode(local.hcloud_network_id)
        token   = base64encode(var.hcloud_token)
      }
    })
  }
}

# Hcloud CCM
data "helm_template" "hcloud_ccm" {
  name      = "hcloud-cloud-controller-manager"
  namespace = "kube-system"

  repository   = var.hcloud_ccm_helm_repository
  chart        = var.hcloud_ccm_helm_chart
  version      = var.hcloud_ccm_helm_version
  kube_version = var.kubernetes_version

  set {
    name  = "kind"
    value = "DaemonSet"
  }
  set {
    name  = "nodeSelector.node-role\\.kubernetes\\.io/control-plane"
    value = ""
  }
  set {
    name  = "networking.enabled"
    value = true
  }
  set {
    name  = "networking.clusterCIDR"
    value = local.pod_ipv4_cidr
  }

  values = [
    yamlencode({
      env = {
        HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP          = { value = "true" }
        HCLOUD_LOAD_BALANCERS_DISABLE_PRIVATE_INGRESS = { value = "true" }
        HCLOUD_LOAD_BALANCERS_LOCATION                = { value = local.hcloud_load_balancer_location }
      }
    }),
    yamlencode(var.hcloud_ccm_helm_values)
  ]
}

locals {
  hcloud_ccm_manifest = {
    name     = "hcloud-ccm"
    contents = data.helm_template.hcloud_ccm.manifest
  }
}

# Hcloud CSI
data "helm_template" "hcloud_csi" {
  count = var.hcloud_csi_enabled ? 1 : 0

  name      = "hcloud-csi"
  namespace = "kube-system"

  repository   = var.hcloud_csi_helm_repository
  chart        = var.hcloud_csi_helm_chart
  version      = var.hcloud_csi_helm_version
  kube_version = var.kubernetes_version

  set {
    name  = "controller.nodeSelector.node-role\\.kubernetes\\.io/control-plane"
    value = ""
  }
  set {
    name  = "controller.tolerations[0].key"
    value = "node-role.kubernetes.io/control-plane"
  }
  set {
    name  = "controller.tolerations[0].effect"
    value = "NoSchedule"
  }
  set {
    name  = "controller.tolerations[0].operator"
    value = "Exists"
  }
  set {
    name  = "controller.replicaCount"
    value = local.control_plane_sum > 1 ? 2 : 1
  }

  set {
    name  = "controller.topologySpreadConstraints[0].topologyKey"
    value = "kubernetes.io/hostname"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].maxSkew"
    value = 1
  }
  set {
    name  = "controller.topologySpreadConstraints[0].whenUnsatisfiable"
    value = local.control_plane_sum > 2 ? "DoNotSchedule" : "ScheduleAnyway"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/component"
    value = "controller"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/instance"
    value = "hcloud-csi"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/name"
    value = "hcloud-csi"
  }

  values = [
    yamlencode(var.hcloud_csi_helm_values)
  ]
}

locals {
  hcloud_csi_manifest = var.hcloud_csi_enabled ? {
    name     = "hcloud-csi"
    contents = data.helm_template.hcloud_csi[0].manifest
  } : null
}
