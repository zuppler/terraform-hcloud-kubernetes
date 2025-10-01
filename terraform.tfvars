# terraform.tfvars - Set required root variables here

cluster_name = "k8s"
hcloud_token = "uEVmWar71XDVDxYH3iNjhkAz8oW3JIAPlWtmKuyDOEtKl99S47NYK9XazuZsONgo"

# Additional Components (disabled by default)
cert_manager_enabled               = true
ingress_nginx_enabled              = true

# Add other required variables below as needed

control_plane_nodepools = [
    { name = "control", type = "cpx31", location = "ash", count = 3 }
  ]
worker_nodepools = [
{ name = "small-worker", type = "ccx23", location = "ash", count = 1 },
{ name = "medium-worker", type = "ccx33", location = "ash", count = 0 },
{ name = "large-worker", type = "ccx43", location = "ash", count = 0 }
]

# Configuration for cluster autoscaler node pools
cluster_autoscaler_nodepools = [
    {
        name = "small-worker", type = "ccx23", location = "ash",
        min = 0, max = 16,
        labels   = { "autoscaler-node" = "true" }
        taints   = [ "autoscaler-node=true:NoExecute" ]
     },
    {
        name = "medium-worker", type = "ccx33", location = "ash",
        min = 0, max = 16,
        labels   = { "autoscaler-node" = "true" }
        taints   = [ "autoscaler-node=true:NoExecute" ]
     },
    {
        name = "large-worker", type = "ccx43", location = "ash",
        min = 0, max = 16,
        labels   = { "autoscaler-node" = "true" }
        taints   = [ "autoscaler-node=true:NoExecute" ]
     }
]

ingress_nginx_kind = "DaemonSet"
ingress_nginx_service_external_traffic_policy = "Local"

ingress_load_balancer_pools = [
  {
    name     = "lb-small"
    location = "ash"
    type     = "lb11"
  }
]

hcloud_csi_storage_classes = [
  {
    name                = "hcloud-volumes"
    encrypted           = false
    defaultStorageClass = true
  },
  {
    name                = "hcloud-volumes-encrypted-xfs"
    encrypted           = true
    reclaimPolicy       = "Retain"
    extraParameters     = {
      "csi.storage.k8s.io/fstype" = "xfs"
      "fsFormatOption"            = "-i nrext64=1"
    }
  }
]

cluster_delete_protection = true