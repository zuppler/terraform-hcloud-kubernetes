locals {
  ingress_nginx_namespace = var.ingress_nginx_enabled ? {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = data.helm_template.ingress_nginx[0].namespace
    }
  } : null

  ingress_nginx_replicas = coalesce(
    var.ingress_nginx_replicas,
    local.worker_sum < 4 ? 2 : 3
  )
}

data "helm_template" "ingress_nginx" {
  count = var.ingress_nginx_enabled ? 1 : 0

  name      = "ingress-nginx"
  namespace = "ingress-nginx"

  repository   = var.ingress_nginx_helm_repository
  chart        = var.ingress_nginx_helm_chart
  version      = var.ingress_nginx_helm_version
  kube_version = var.kubernetes_version

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

  values = [
    yamlencode({
      controller = {
        kind         = var.ingress_nginx_kind
        replicaCount = local.ingress_nginx_replicas
        topologySpreadConstraints = [
          {
            topologyKey = "kubernetes.io/hostname"
            maxSkew     = 1
            whenUnsatisfiable = (
              local.worker_sum > local.ingress_nginx_replicas ?
              "DoNotSchedule" :
              "ScheduleAnyway"
            )
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/instance"  = "ingress-nginx"
                "app.kubernetes.io/name"      = "ingress-nginx"
                "app.kubernetes.io/component" = "controller"
              }
            }
          }
        ]
        watchIngressWithoutClass = true
      }
    }),
    yamlencode(var.ingress_nginx_helm_values)
  ]
}

locals {
  ingress_nginx_manifest = var.ingress_nginx_enabled ? {
    name     = "ingress-nginx"
    contents = <<-EOF
      ${yamlencode(local.ingress_nginx_namespace)}
      ---
      ${data.helm_template.ingress_nginx[0].manifest}
    EOF
  } : null

  depends_on = [hcloud_load_balancer_network.ingress]
}
