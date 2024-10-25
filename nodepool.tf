locals {
  control_plane_nodepools = [
    for np in var.control_plane_nodepools : {
      name        = np.name,
      location    = np.location,
      server_type = np.type,
      backups     = np.backups,
      keep_disk   = np.keep_disk,
      labels = merge(
        np.labels,
        { "nodepool" = np.name }
      ),
      annotations = np.annotations,
      taints = [for taint in np.taints : regex(
        "^(?P<key>[^=]+)=(?P<value>[^:]+):(?P<effect>.+)$",
        taint
      )],
      count = np.count,
    }
  ]

  worker_nodepools = [
    for np in var.worker_nodepools : {
      name        = np.name,
      location    = np.location,
      server_type = np.type,
      backups     = np.backups,
      keep_disk   = np.keep_disk,
      labels = merge(
        np.labels,
        { "nodepool" = np.name }
      ),
      annotations = np.annotations,
      taints = [for taint in np.taints : regex(
        "^(?P<key>[^=]+)=(?P<value>[^:]+):(?P<effect>.+)$",
        taint
      )],
      count           = np.count,
      placement_group = np.placement_group
    }
  ]

  autoscaler_nodepools = [
    for np in var.autoscaler_nodepools : {
      name        = np.name,
      location    = np.location,
      server_type = np.type,
      labels = merge(
        np.labels,
        { "nodepool" = np.name }
      ),
      annotations = np.annotations,
      taints = [for taint in np.taints : regex(
        "^(?P<key>[^=]+)=(?P<value>[^:]+):(?P<effect>.+)$",
        taint
      )],
      min = np.min,
      max = np.max
    }
  ]

  control_plane_sum  = length(local.control_plane_nodepools) > 0 ? sum(local.control_plane_nodepools[*].count) : 0
  worker_sum         = length(local.worker_nodepools) > 0 ? sum(local.worker_nodepools[*].count) : 0
  autoscaler_min_sum = length(local.autoscaler_nodepools) > 0 ? sum(local.autoscaler_nodepools[*].min) : 0
  autoscaler_max_sum = length(local.autoscaler_nodepools) > 0 ? sum(local.autoscaler_nodepools[*].max) : 0
}
