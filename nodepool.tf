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
      taints = concat(
        [for taint in np.taints : regex(
          "^(?P<key>[^=:]+)=?(?P<value>[^:]*):(?P<effect>.+)$",
          taint
        )],
        local.allow_scheduling_on_control_plane ? [] : [
          { key = "node-role.kubernetes.io/control-plane", value = "", effect = "NoSchedule" }
        ]
      ),
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
        "^(?P<key>[^=:]+)=?(?P<value>[^:]*):(?P<effect>.+)$",
        taint
      )],
      count           = np.count,
      placement_group = np.placement_group
    }
  ]

  cluster_autoscaler_nodepools = [
    for np in var.cluster_autoscaler_nodepools : {
      name        = np.name,
      location    = np.location,
      server_type = np.type,
      labels = merge(
        np.labels,
        { "nodepool" = np.name }
      ),
      annotations = np.annotations,
      taints = [for taint in np.taints : regex(
        "^(?P<key>[^=:]+)=?(?P<value>[^:]*):(?P<effect>.+)$",
        taint
      )],
      min = np.min,
      max = np.max
    }
  ]

  control_plane_nodepools_map      = { for np in local.control_plane_nodepools : np.name => np }
  worker_nodepools_map             = { for np in local.worker_nodepools : np.name => np }
  cluster_autoscaler_nodepools_map = { for np in local.cluster_autoscaler_nodepools : np.name => np }

  control_plane_sum          = length(local.control_plane_nodepools) > 0 ? sum(local.control_plane_nodepools[*].count) : 0
  worker_sum                 = length(local.worker_nodepools) > 0 ? sum(local.worker_nodepools[*].count) : 0
  cluster_autoscaler_min_sum = length(local.cluster_autoscaler_nodepools) > 0 ? sum(local.cluster_autoscaler_nodepools[*].min) : 0
  cluster_autoscaler_max_sum = length(local.cluster_autoscaler_nodepools) > 0 ? sum(local.cluster_autoscaler_nodepools[*].max) : 0
}
