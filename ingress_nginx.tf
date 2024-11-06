locals {
  ingress_nginx_namespace = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = data.helm_template.ingress_nginx.namespace
    }
  }
}

data "helm_template" "ingress_nginx" {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  repository   = "https://kubernetes.github.io/ingress-nginx"
  chart        = "ingress-nginx"
  version      = var.ingress_nginx_version
  kube_version = var.kubernetes_version

  set {
    name  = "controller.kind"
    value = var.ingress_nginx_kind
  }
  set {
    name  = "controller.replicaCount"
    value = coalesce(var.ingress_nginx_replicas, (local.worker_sum + local.cluster_autoscaler_max_sum) < 4 ? 2 : 3)
  }
  set {
    name  = "controller.admissionWebhooks.certManager.enabled"
    value = true
  }
  set {
    name  = "controller.config.compute-full-forwarded-for"
    value = true
  }
  set {
    name  = "controller.config.proxy-real-ip-cidr"
    value = hcloud_network_subnet.load_balancer.ip_range
  }
  set {
    name  = "controller.config.use-proxy-protocol"
    value = true
  }
  set {
    name  = "controller.watchIngressWithoutClass"
    value = true
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
    value = (local.worker_sum + local.cluster_autoscaler_max_sum) > coalesce(var.ingress_nginx_replicas, (local.worker_sum + local.cluster_autoscaler_max_sum)) ? "DoNotSchedule" : "ScheduleAnyway"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/name"
    value = "ingress-nginx"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/instance"
    value = "ingress-nginx"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/component"
    value = "controller"
  }

  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/algorithm-type"
    value = var.ingress_load_balancer_algorithm
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/disable-private-ingress"
    value = true
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/disable-public-network"
    value = !var.ingress_load_balancer_public_network_enabled
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/health-check-interval"
    value = "3s"
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/health-check-retries"
    value = 3
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/health-check-timeout"
    value = "3s"
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/hostname"
    value = local.ingress_load_balancer_hostname
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/ipv6-disabled"
    value = false
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/location"
    value = local.ingress_load_balancer_location
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/name"
    value = local.ingress_load_balancer_name
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/type"
    value = var.ingress_load_balancer_type
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/use-private-ip"
    value = true
  }
  set {
    name  = "controller.service.annotations.load-balancer\\.hetzner\\.cloud/uses-proxyprotocol"
    value = true
  }
}

locals {
  ingress_nginx_manifest = {
    name     = "ingress-nginx"
    contents = <<-EOF
      ${yamlencode(local.ingress_nginx_namespace)}
      ---
      ${data.helm_template.ingress_nginx.manifest}
    EOF
  }

  depends_on = [hcloud_load_balancer_network.ingress]
}
