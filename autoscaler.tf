locals {
  cluster_autoscaler_enabled = length(local.cluster_autoscaler_nodepools) > 0

  cluster_autoscaler_cluster_config = local.cluster_autoscaler_enabled ? {
    imagesForArch = {
      arm64 = local.image_label_selector,
      amd64 = local.image_label_selector
    },
    nodeConfigs = {
      for nodepool in local.cluster_autoscaler_nodepools : "${var.cluster_name}-${nodepool.name}" => {
        cloudInit = data.talos_machine_configuration.cluster_autoscaler[nodepool.name].machine_configuration,
        labels    = nodepool.labels
        taints    = nodepool.taints
      }
    }
  } : null
}

data "helm_template" "cluster_autoscaler" {
  count = local.cluster_autoscaler_enabled ? 1 : 0

  name      = "cluster-autoscaler"
  namespace = "kube-system"

  repository   = var.cluster_autoscaler_helm_repository
  chart        = var.cluster_autoscaler_helm_chart
  version      = var.cluster_autoscaler_helm_version
  kube_version = var.kubernetes_version

  set {
    name  = "image.tag"
    value = "v1.31.1"
  }
  set {
    name  = "cloudProvider"
    value = "hetzner"
  }
  set {
    name  = "extraEnvSecrets.HCLOUD_TOKEN.name"
    value = "hcloud"
  }
  set {
    name  = "extraEnvSecrets.HCLOUD_TOKEN.key"
    value = "token"
  }
  set {
    name  = "extraEnv.HCLOUD_CLUSTER_CONFIG"
    value = base64encode(jsonencode(local.cluster_autoscaler_cluster_config))
  }
  set {
    name  = "extraEnv.HCLOUD_SERVER_CREATION_TIMEOUT"
    value = 10
  }
  set {
    name  = "extraEnv.HCLOUD_FIREWALL"
    value = hcloud_firewall.this.id
  }
  set {
    name  = "extraEnv.HCLOUD_SSH_KEY"
    value = hcloud_ssh_key.this.id
  }
  set {
    name  = "extraEnv.HCLOUD_PUBLIC_IPV4"
    value = var.talos_public_ipv4_enabled
  }
  set {
    name  = "extraEnv.HCLOUD_PUBLIC_IPV6"
    value = var.talos_public_ipv6_enabled
  }
  set {
    name  = "extraEnv.HCLOUD_NETWORK"
    value = hcloud_network_subnet.autoscaler.network_id
  }

  set {
    name  = "nodeSelector.node-role\\.kubernetes\\.io/control-plane"
    value = ""
  }
  set {
    name  = "tolerations[0].key"
    value = "node-role.kubernetes.io/control-plane"
  }
  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }
  set {
    name  = "replicaCount"
    value = local.control_plane_sum > 1 ? 2 : 1
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
    value = local.control_plane_sum > 2 ? "DoNotSchedule" : "ScheduleAnyway"
  }
  set {
    name  = "topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/instance"
    value = "cluster-autoscaler"
  }
  set {
    name  = "topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/name"
    value = "hetzner-cluster-autoscaler"
  }

  values = [
    yamlencode({
      autoscalingGroups = [
        for np in local.cluster_autoscaler_nodepools : {
          name         = "${var.cluster_name}-${np.name}",
          minSize      = np.min,
          maxSize      = np.max,
          instanceType = np.server_type,
          region       = np.location
        }
      ]
    }),
    yamlencode(var.cluster_autoscaler_helm_values)
  ]

  depends_on = [
    terraform_data.amd64_image,
    terraform_data.arm64_image,
  ]
}

locals {
  cluster_autoscaler_manifest = local.cluster_autoscaler_enabled ? {
    name     = "cluster-autoscaler"
    contents = data.helm_template.cluster_autoscaler[0].manifest
  } : null
}
