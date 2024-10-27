locals {
  allow_scheduling_on_control_plane = ((local.worker_sum + local.autoscaler_max_sum) == 0)

  # Kubernetes Manifests for Talos
  talos_inline_manifests = concat(
    [
      local.talos_backup_manifest,
      local.hcloud_secret_manifest,
      local.hcloud_ccm_manifest,
      local.cilium_manifest
    ],
    var.hcloud_csi_enabled ? [local.hcloud_csi_manifest] : [],
    var.metrics_server_enabled ? [local.metrics_server_manifest] : [],
    var.cert_manager_enabled ? [local.cert_manager_manifest] : [],
    var.ingress_nginx_enabled ? [local.ingress_nginx_manifest] : [],
    length(local.autoscaler_nodepools) > 0 ? [local.cluster_autoscaler_manifest] : []
  )
  talos_manifests = [
    "https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/${var.talos_ccm_version}/docs/deploy/cloud-controller-manager-daemonset.yml",
    "https://github.com/prometheus-operator/prometheus-operator/releases/download/${var.prometheus_operator_crds_version}/stripped-down-crds.yaml"
  ]

  # Talos and Kubernetes Certificates
  certificate_san = distinct(
    compact(
      concat(
        var.control_plane_public_vip_ipv4_enabled ? [local.control_plane_public_vip_ipv4] : [],
        [local.control_plane_private_vip_ipv4],
        [local.kube_api_load_balancer_private_ipv4],
        local.control_plane_public_ipv4_list,
        local.control_plane_private_ipv4_list,
        local.control_plane_public_ipv6_list,
        [local.kube_api_host],
        ["127.0.0.1", "::1", "localhost"],
      )
    )
  )

  talos_host_dns = {
    enabled              = true
    forwardKubeDNSToHost = false
    resolveMemberNames   = true
  }

  # Extra Host Entries
  extra_host_entries = concat(
    var.kube_api_hostname != null ? [
      {
        ip      = local.kube_api_private_ipv4
        aliases = [var.kube_api_hostname]
      }
    ] : [],
    var.talos_extra_host_entries
  )

  # Disk Encryption
  systemDiskEncryption = var.talos_system_disk_encryption_enabled ? {
    state = {
      provider = "luks2"
      options  = ["no_read_workqueue", "no_write_workqueue"]
      keys = [{
        nodeID = {}
        slot   = 0
      }]
    }
    ephemeral = {
      provider = "luks2"
      options  = ["no_read_workqueue", "no_write_workqueue"]
      keys = [{
        nodeID = {}
        slot   = 0
      }]
    }
  } : {}

  # Control Plane Config
  control_plane_nodepool_config = {
    for nodepool in local.control_plane_nodepools : nodepool.name => {
      machine = {
        install = { image = local.talos_installer_image_url }
        nodeLabels = merge(
          #local.allow_scheduling_on_control_plane ? { "node.kubernetes.io/exclude-from-external-load-balancers" = { "$patch" = "delete" } } : {},
          local.allow_scheduling_on_control_plane ? {} : { "node.kubernetes.io/exclude-from-external-load-balancers" = "" },
          nodepool.labels
        )
        nodeAnnotations = nodepool.annotations
        nodeTaints = {
          for taint in nodepool.taints : taint.key => "${taint.value}:${taint.effect}"
        }
        certSANs = local.certificate_san
        network = {
          interfaces = [
            {
              interface = "eth0"
              dhcp      = true
              dhcpOptions = {
                ipv4 = var.talos_public_ipv4_enabled
                ipv6 = false
              }
              vip = local.control_plane_public_vip_ipv4_enabled ? {
                ip = local.control_plane_public_vip_ipv4
                hcloud = {
                  apiToken = var.hcloud_token
                }
              } : null
            },
            {
              interface = "eth1"
              dhcp      = true
              routes    = local.talos_extra_routes
              vip = var.control_plane_private_vip_ipv4_enabled ? {
                ip = local.control_plane_private_vip_ipv4
                hcloud = {
                  apiToken = var.hcloud_token
                }
              } : null
            }
          ]
          nameservers      = var.talos_nameservers
          extraHostEntries = local.extra_host_entries
        }
        kubelet = {
          extraArgs = merge(
            {
              "cloud-provider"             = "external"
              "rotate-server-certificates" = true
            },
            var.kubernetes_kubelet_extra_args
          )
          extraConfig = {
            shutdownGracePeriod             = "90s"
            shutdownGracePeriodCriticalPods = "15s"
            systemReserved = {
              cpu               = "250m"
              memory            = "300Mi"
              ephemeral-storage = "1Gi"
            }
            kubeReserved = {
              cpu               = "250m"
              memory            = "1500Mi"
              ephemeral-storage = "1Gi"
            }
          }
          nodeIP = {
            validSubnets = [local.node_ipv4_cidr]
          }
        }
        kernel = {
          modules = var.talos_kernel_modules_to_load
        }
        sysctls = merge(
          {
            "net.core.somaxconn"                 = "65535",
            "net.core.netdev_max_backlog"        = "4096",
            "net.ipv6.conf.default.disable_ipv6" = "${var.talos_ipv6_enabled ? 0 : 1}",
            "net.ipv6.conf.all.disable_ipv6"     = "${var.talos_ipv6_enabled ? 0 : 1}"
          },
          var.talos_sysctls_extra_args
        )
        registries           = var.talos_registries
        systemDiskEncryption = local.systemDiskEncryption
        features = {
          kubernetesTalosAPIAccess = {
            enabled = true,
            allowedRoles = [
              "os:reader",
              "os:etcd:backup"
            ],
            allowedKubernetesNamespaces = ["kube-system"]
          },
          hostDNS = local.talos_host_dns
        }
        time = {
          servers = var.talos_time_servers
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = local.allow_scheduling_on_control_plane
        network = {
          dnsDomain      = var.cluster_domain
          podSubnets     = [local.pod_ipv4_cidr]
          serviceSubnets = [local.service_ipv4_cidr]
          cni            = { name = "none" }
        }
        coreDNS = {
          disabled = !var.talos_coredns_enabled
        }
        proxy = {
          disabled = true
        }
        apiServer = {
          certSANs = local.certificate_san,
          extraArgs = merge(
            { "enable-aggregator-routing" = true },
            var.kube_api_extra_args
          )
        }
        controllerManager = {
          extraArgs = { "cloud-provider" = "external" }
        }
        discovery = {
          enabled = true,
          registries = {
            kubernetes = { disabled = false }
            service    = { disabled = true }
          }
        }
        etcd = {
          advertisedSubnets = [hcloud_network_subnet.control_plane.ip_range]
          advertisedSubnets = [hcloud_network_subnet.control_plane.ip_range]
          extraArgs = {
            "listen-metrics-urls" = "http://0.0.0.0:2381"
          }
        }
        scheduler = {
          extraArgs = {
            "bind-address" = "0.0.0.0"
          }
        }
        adminKubeconfig = {
          certLifetime = "87600h"
        }
        inlineManifests = local.talos_inline_manifests
        externalCloudProvider = {
          enabled   = true,
          manifests = local.talos_manifests
        }
      }
    }
  }

  # Worker Config
  worker_nodepool_config = {
    for nodepool in local.worker_nodepools : nodepool.name => {
      machine = {
        install         = { image = local.talos_installer_image_url }
        nodeLabels      = nodepool.labels
        nodeAnnotations = nodepool.annotations
        certSANs        = local.certificate_san
        network = {
          interfaces = [
            {
              interface = "eth0"
              dhcp      = true
              dhcpOptions = {
                ipv4 = var.talos_public_ipv4_enabled
                ipv6 = false
              }
            },
            {
              interface = "eth1"
              dhcp      = true
              routes    = local.talos_extra_routes
            }
          ]
          nameservers      = var.talos_nameservers
          extraHostEntries = local.extra_host_entries
        }
        kubelet = {
          extraArgs = merge(
            {
              "cloud-provider"             = "external",
              "rotate-server-certificates" = true
            },
            var.kubernetes_kubelet_extra_args
          )
          extraConfig = {
            shutdownGracePeriod             = "90s"
            shutdownGracePeriodCriticalPods = "15s"
            registerWithTaints              = nodepool.taints
            systemReserved = {
              cpu               = "100m"
              memory            = "300Mi"
              ephemeral-storage = "1Gi"
            }
            kubeReserved = {
              cpu               = "100m"
              memory            = "350Mi"
              ephemeral-storage = "1Gi"
            }
          }
          nodeIP = {
            validSubnets = [local.node_ipv4_cidr]
          }
        }
        kernel = {
          modules = var.talos_kernel_modules_to_load
        }
        sysctls = merge(
          {
            "net.core.somaxconn"                 = "65535"
            "net.core.netdev_max_backlog"        = "4096"
            "net.ipv6.conf.default.disable_ipv6" = "${var.talos_ipv6_enabled ? 0 : 1}"
            "net.ipv6.conf.all.disable_ipv6"     = "${var.talos_ipv6_enabled ? 0 : 1}"
          },
          var.talos_sysctls_extra_args
        )
        registries           = var.talos_registries
        systemDiskEncryption = local.systemDiskEncryption
        features = {
          hostDNS = local.talos_host_dns
        }
        time = {
          servers = var.talos_time_servers
        }
      }
      cluster = {
        network = {
          dnsDomain      = var.cluster_domain
          podSubnets     = [local.pod_ipv4_cidr]
          serviceSubnets = [local.service_ipv4_cidr]
          cni            = { name = "none" }
        }
        proxy = {
          disabled = true
        }
        discovery = {
          enabled = true,
          registries = {
            kubernetes = { disabled = false }
            service    = { disabled = true }
          }
        }
      }
    }
  }

  # Autoscaler Config
  autoscaler_nodepool_config = {
    for nodepool in local.autoscaler_nodepools : nodepool.name => {
      machine = {
        install         = { image = local.talos_installer_image_url }
        nodeLabels      = nodepool.labels
        nodeAnnotations = nodepool.annotations
        certSANs        = local.certificate_san
        network = {
          interfaces = [
            {
              interface = "eth0"
              dhcp      = true
              dhcpOptions = {
                ipv4 = var.talos_public_ipv4_enabled
                ipv6 = false
              }
            },
            {
              interface = "eth1"
              dhcp      = true
              routes    = local.talos_extra_routes
            }
          ]
          nameservers      = var.talos_nameservers
          extraHostEntries = local.extra_host_entries
        }
        kubelet = {
          extraArgs = merge(
            {
              "cloud-provider"             = "external"
              "rotate-server-certificates" = true
            },
            var.kubernetes_kubelet_extra_args
          )
          extraConfig = {
            shutdownGracePeriod             = "90s"
            shutdownGracePeriodCriticalPods = "15s"
            registerWithTaints              = nodepool.taints
            systemReserved = {
              cpu               = "100m"
              memory            = "300Mi"
              ephemeral-storage = "1Gi"
            }
            kubeReserved = {
              cpu               = "100m"
              memory            = "350Mi"
              ephemeral-storage = "1Gi"
            }
          }
          nodeIP = {
            validSubnets = [local.node_ipv4_cidr]
          }
        }
        kernel = {
          modules = var.talos_kernel_modules_to_load
        }
        sysctls = merge(
          {
            "net.core.somaxconn"                 = "65535"
            "net.core.netdev_max_backlog"        = "4096"
            "net.ipv6.conf.default.disable_ipv6" = "${var.talos_ipv6_enabled ? 0 : 1}"
            "net.ipv6.conf.all.disable_ipv6"     = "${var.talos_ipv6_enabled ? 0 : 1}"
          },
          var.talos_sysctls_extra_args
        )
        registries           = var.talos_registries
        systemDiskEncryption = local.systemDiskEncryption
        features = {
          hostDNS = local.talos_host_dns
        }
        time = {
          servers = var.talos_time_servers
        }
      }
      cluster = {
        network = {
          dnsDomain      = var.cluster_domain
          podSubnets     = [local.pod_ipv4_cidr]
          serviceSubnets = [local.service_ipv4_cidr]
          cni            = { name = "none" }
        }
        proxy = {
          disabled = true
        }
        discovery = {
          enabled = true,
          registries = {
            kubernetes = { disabled = false }
            service    = { disabled = true }
          }
        }
      }
    }
  }
}

data "talos_machine_configuration" "control_plane" {
  for_each = { for nodepool in local.control_plane_nodepools : nodepool.name => nodepool }

  talos_version      = var.talos_version
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.kube_api_url_internal
  kubernetes_version = var.kubernetes_version
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  config_patches     = [yamlencode(local.control_plane_nodepool_config[each.key])]
  docs               = false
  examples           = false
}

data "talos_machine_configuration" "worker" {
  for_each = { for nodepool in local.worker_nodepools : nodepool.name => nodepool }

  talos_version      = var.talos_version
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.kube_api_url_internal
  kubernetes_version = var.kubernetes_version
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  config_patches     = [yamlencode(local.worker_nodepool_config[each.key])]
  docs               = false
  examples           = false
}

data "talos_machine_configuration" "autoscaler" {
  for_each = { for nodepool in local.autoscaler_nodepools : nodepool.name => nodepool }

  talos_version      = var.talos_version
  cluster_name       = var.cluster_name
  cluster_endpoint   = local.kube_api_url_internal
  kubernetes_version = var.kubernetes_version
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  config_patches     = [yamlencode(local.autoscaler_nodepool_config[each.key])]
  docs               = false
  examples           = false
}
