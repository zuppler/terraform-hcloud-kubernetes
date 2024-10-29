<div align="center">

  <img src="https://raw.githubusercontent.com/hcloud-k8s/terraform-hcloud-kubernetes/refs/heads/main/assets/hcloud-k8s.png" alt="logo" width="200" height="auto" />
  <h1>Hcloud Kubernetes</h1>

  <p>
    Terraform Module to deploy Kubernetes on Hetzner Cloud! 
  </p>

<!-- Badges -->
<p>
  <a href="">
    <img src="https://img.shields.io/github/release/hcloud-k8s/terraform-hcloud-kubernetes?logo=github" alt="last update" />
  </a>
  <a href="">
    <img src="https://img.shields.io/github/last-commit/hcloud-k8s/terraform-hcloud-kubernetes?logo=github" alt="last update" />
  </a>
  <a href="https://github.com/hcloud-k8s/terraform-hcloud-kubernetes/network/members">
    <img src="https://img.shields.io/github/forks/hcloud-k8s/terraform-hcloud-kubernetes" alt="forks" />
  </a>
  <a href="https://github.com/hcloud-k8s/terraform-hcloud-kubernetes/stargazers">
    <img src="https://img.shields.io/github/stars/hcloud-k8s/terraform-hcloud-kubernetes" alt="stars" />
  </a>
  <a href="https://github.com/hcloud-k8s/terraform-hcloud-kubernetes/issues/">
    <img src="https://img.shields.io/github/issues/hcloud-k8s/terraform-hcloud-kubernetes?logo=github" alt="open issues" />
  </a>
  <a href="https://github.com/hcloud-k8s/terraform-hcloud-kubernetes/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/hcloud-k8s/terraform-hcloud-kubernetes?logo=github" alt="license" />
  </a>
</p>

</div>

<br />

<!-- Table of Contents -->
# :notebook_with_decorative_cover: Table of Contents
- [:star2: About the Project](#star2-about-the-project)
- [:rocket: Getting Started](#rocket-getting-started)
- [:hammer_and_pick: Advanced Configuration](#hammer_and_pick-advanced-configuration)
- [:recycle: Lifecycle](#recycle-lifecycle)
- [:compass: Roadmap](#compass-roadmap)
- [:wave: Contributing](#wave-contributing)
- [:balance_scale: License](#balance_scale-license)
- [:gem: Acknowledgements](#gem-acknowledgements)

<!-- About the Project -->
## :star2: About the Project
Hcloud Kubernetes is a Terraform module for deploying a fully declarative, managed Kubernetes cluster on Hetzner Cloud. It utilizes Talos, a secure, immutable, and minimal operating system specifically designed for Kubernetes, featuring a streamlined architecture with just 12 binaries and managed entirely through an API.

This project is committed to production-grade configuration and lifecycle management, ensuring all components are set up for high availability. It includes a curated selection of widely used and officially recognized Kubernetes components. If you encounter any issues, suboptimal settings, or missing elements, please file an [issue](https://github.com/hcloud-k8s/terraform-hcloud-kubernetes/issues) to help us improve this project.

> [!TIP]
> If you don't yet have a Hetzner account, feel free to use this [Hetzner Cloud Referral Link](https://hetzner.cloud/?ref=GMylKeDmqtsD) to claim a €20 credit and support this project.

<!-- Features -->
### :sparkles: Features

This setup includes several features for a seamless, best-practice Kubernetes deployment on Hetzner Cloud:
- **Fully Declarative & Immutable**: Utilize Talos Linux for a completely declarative and immutable Kubernetes setup on Hetzner Cloud.
- **Cross-Architecture**: Supports both AMD64 and ARM64 architectures, with integrated image upload to Hetzner Cloud.
- **High Availability**: Configured for production-grade high availability, ensuring consistent and reliable system performance.
- **Autoscaling**: Includes Cluster Autoscaler to dynamically adjust node counts based on workload demands, optimizing resource allocation.
- **Plug-and-Play Kubernetes**: Equipped with an optional Ingress Controller and Cert Manager, facilitating rapid workload deployment.
- **Dual-Stack Ingress**: Employs Hetzner Load Balancers with Proxy Protocol to efficiently route both IPv4 and IPv6 traffic to the Ingress Controller.
- **Enhanced Security**: Built with security as a priority, incorporating firewalls and encryption by default to protect your infrastructure.
- **Automated Backups**: Leverages Talos Backup with support for S3-compatible storage solutions like Hetzner's Object Storage.

<!-- Components -->
### :package: Components
This project includes commonly used and essential Kubernetes software, optimized for seamless integration with Hetzner Cloud.

- **[Talos Cloud Controller Manager (CCM)](https://github.com/siderolabs/talos-cloud-controller-manager)**<br>
  Manages node resources by updating with cloud metadata, handling lifecycle deletions, and automatically approving node CSRs.
- **[Talos Backup](https://github.com/siderolabs/talos-backup)**<br>
  Automates etcd snapshots and S3 storage for backup in Talos Linux-based Kubernetes clusters.
- **[Hcloud Cloud Controller Manager (CCM)](https://github.com/hetznercloud/hcloud-cloud-controller-manager)**<br>
  Manages the integration of Kubernetes clusters with Hetzner Cloud services, ensuring the update of node data, private network traffic control, and load balancer setup.
- **[Hcloud Container Storage Interface (CSI)](https://github.com/hetznercloud/hcloud-cloud-controller-manager)**<br>
  Manages persistent storage in Kubernetes clusters using Hetzner Cloud Volumes, ensuring seamless storage integration and management.
- **[Cilium Container Network Interface (CNI)](https://cilium.io)**<br>
  A high performance CNI plugin that enhances and secures network connectivity and observability for container workloads through the use of eBPF technology in Linux kernels.
- **[Ingress NGINX Controller](https://kubernetes.github.io/ingress-nginx/)**<br>
  Provides a robust web routing and load balancing solution for Kubernetes, utilizing NGINX as a reverse proxy to manage traffic and enhance network performance.
- **[Cert Manager](https://cert-manager.io)**<br>
  Automates the management of certificates in Kubernetes, handling the issuance and renewal of certificates from various sources like Let's Encrypt, and ensures certificates are valid and updated.
- **[Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)**<br>
  Dynamically adjusts Kubernetes cluster size based on resource demands and node utilization, scaling nodes in or out to optimize cost and performance.
- **[Metrics Server](https://kubernetes-sigs.github.io/metrics-server/)**<br>
  Collects and provides container resource metrics for Kubernetes, enabling features like autoscaling by interacting with Horizontal and Vertical Pod Autoscalers.

<!-- Security -->
### :shield: Security
Talos Linux is a secure, minimal, and immutable OS for Kubernetes, removing SSH and shell access to reduce attack surfaces. Managed through a secure API with mTLS, Talos prevents configuration drift, enhancing both security and predictability. It follows [NIST](https://www.nist.gov/publications/application-container-security-guide) and [CIS](https://www.cisecurity.org/benchmark/kubernetes) hardening standards, operates in memory, and is built to support modern, production-grade Kubernetes environments.

**Firewall Protection:** This module uses [Hetzner Cloud Firewalls](https://docs.hetzner.com/cloud/firewalls/) to manage external access to nodes. For internal pod-to-pod communication, support for Kubernetes Network Policies is provided through [Cilium CNI](https://docs.cilium.io/en/stable/network/kubernetes/policy/).

**Encryption in Transit:** In this module, all pod network traffic is encrypted by default using [WireGuard via Cilium CNI](https://cilium.io/use-cases/transparent-encryption/). It includes automatic key rotation and efficient in-kernel encryption, covering all traffic types.

**Encryption at Rest:** In this module, the [STATE](https://www.talos.dev/latest/learn-more/architecture/#file-system-partitions) and [EPHEMERAL](https://www.talos.dev/latest/learn-more/architecture/#file-system-partitions) partitions are encrypted by default with [Talos Disk Encryption](https://www.talos.dev/latest/talos-guides/configuration/disk-encryption/) using LUKS2. Each node is secured with individual encryption keys derived from its unique `nodeID`.

<!-- Getting Started -->
## 	:rocket: Getting Started

<!-- Prerequisites -->
### :heavy_check_mark: Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/install) to deploy Kubernetes on Hetzner Cloud
- [packer](https://developer.hashicorp.com/packer/install) to upload Talos Images to Hetzner Cloud
- [talosctl](https://www.talos.dev/latest/talos-guides/install/talosctl/) to control the Talos Cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) to control Kubernetes (optional)

> [!IMPORTANT]
> Keep the CLI tools up to date. Ensure that `talosctl` matches your Talos version for compatibility, especially before a Talos upgrade.

<!-- Installation -->
### :dart: Installation

Create `kubernetes.tf` file with the module configuration:
```hcl
module "kubernetes" {
  source  = "hcloud-k8s/kubernetes/hcloud"
  version = "<version>"

  cluster_name = "k8s"
  hcloud_token = "<hcloud-token>"

  # Export configs for Talos and Kube API access
  cluster_kubeconfig_path  = "kubeconfig"
  cluster_talosconfig_path = "talosconfig"

  # Optional Ingress Controller and Cert Manager
  cert_manager_enabled  = true
  ingress_nginx_enabled = true

  control_plane_nodepools = [
    { name = "control", type = "cax11", location = "fsn1", count = 3 }
  ]
  worker_nodepools = [
    { name = "worker", type = "cax11", location = "fsn1", count = 3 }
  ]
}
```
> [!NOTE]
> For a High-Availability (HA) setup, you’ll need at least 3 control plane nodes and 3 worker nodes.

Initialize Terraform and deploy the cluster:

```sh
terraform init --upgrade
terraform apply
```


<!-- Cluster Access -->
### :key: Cluster Access

Set config file locations:
```sh
export TALOSCONFIG=./talosconfig
export KUBECONFIG=./kubeconfig
```

Display cluster nodes:
```sh
talosctl get member
kubectl get nodes -o wide
```

Display all pods:
```sh
kubectl get pods -A
```

For more detailed information and examples, please visit:
- [Talos CLI Documentation](https://www.talos.dev/v1.8/reference/cli/)
- [Kubernetes CLI Documentation](https://kubernetes.io/docs/reference/kubectl/introduction/)

<!-- Advanced Configuration -->
## :hammer_and_pick: Advanced Configuration

<details>
<summary>Cluster Autoscaler</summary>
The Cluster Autoscaler dynamically adjusts the number of nodes in a Kubernetes cluster based on the demand, ensuring that there are enough nodes to run all pods and no unneeded nodes when the workload decreases.

Example `kubernetes.tf` snippet:
```hcl
# Optionally enforce always having the minimum number of nodes
autoscaler_enforce_node_group_min_size = true

# Configure autoscaler nodepools
autoscaler_nodepools = [
  {
    name     = "autoscaler"
    type     = "cax11"
    location = "fsn1"
    min      = 2
    max      = 6
    labels   = { "autoscaler-node" = "true" }
    taints   = [ "autoscaler-node=true:NoExecute" ]
  }
]
```

</details>

<details>
<summary>Egress Gateway</summary>
Cilium offers an Egress Gateway to ensure network compatibility with legacy systems and firewalls requiring fixed IPs. The use of Cilium Egress Gateway does not provide high availability and increases latency due to extra network hops and tunneling. Consider this configuration only as a last resort.

Example `kubernetes.tf` snippet:
```hcl
# Enable Cilium Egress Gateway
cilium_egress_gateway_enabled = true

# Define worker nodepools including an egress-specific node pool
worker_nodepools = [
  # ... (other node pool configurations)
  {
    name     = "egress"
    type     = "cax11"
    location = "fsn1"
    labels   = { "egress-node" = "true" }
    taints   = [ "egress-node=true:NoSchedule" ]
  }
]
```

Example Egress Gateway Policy:
```yml
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: sample-egress-policy
spec:
  selectors:
    - podSelector:
        matchLabels:
          io.kubernetes.pod.namespace: sample-namespace
          app: sample-app

  destinationCIDRs:
    - "0.0.0.0/0"

  egressGateway:
    nodeSelector:
      matchLabels:
        egress-node: "true"
```

Please visit the Cilium [documentation](https://docs.cilium.io/en/stable/network/egress-gateway) for more details.
</details>


<!-- Lifecycle -->
## :recycle: Lifecycle
The [Talos Terraform Provider](https://registry.terraform.io/providers/siderolabs/talos) does not support declarative upgrades of Talos or Kubernetes versions. This module compensates for these limitations using `talosctl` to implement the required functionalities. Any minor or major upgrades to Talos and Kubernetes will result in a major version change of this module. Please be aware that downgrades are typically neither supported nor tested.

> [!IMPORTANT]
> Before upgrading to the next major version of this module, ensure you are on the latest release of the current major version. Do not skip any major release upgrades.

### :white_check_mark: Version Compatibility Matrix
| Hcloud Kubernetes |  K8s   | Talos | Talos CCM | Hcloud CCM | Hcloud CSI | Cilium | Ingress NGINX | Cert Manager | Auto-scaler |
| :---------------: | :----: | :---: | :-------: | :--------: | :--------: | :----: | :-----------: | :----------: | :---------: |
|      (**2**)      | (1.32) | (1.9) |     ?     |     ?      |     ?      |   ?    |       ?       |      ?       |      ?      |
|      (**1**)      |  1.31  |  1.8  |    1.8    |   (1.21)   |   (2.10)   | (1.17) |    (4.12)     |     1.15     |    9.38     |
|       **0**       |  1.30  |  1.7  |    1.6    |    1.20    |    2.9     |  1.16  |    4.10.1     |     1.14     |    9.37     |

In this module, upgrades are conducted with care and conservatism. You will consistently receive the most tested and compatible releases of all components, avoiding the latest untested or incompatible releases that could disrupt your cluster.

> [!WARNING]
> Do not change any software versions in this project on your own. Each component is tailored to ensure compatibility with new Kubernetes releases. This project specifies versions that are supported and have been thoroughly tested to work together.

<!--
- Talos/K8s: https://github.com/siderolabs/talos/blob/release-1.6/pkg/machinery/constants/constants.go
- HCCM: https://github.com/hetznercloud/hcloud-cloud-controller-manager/tree/main?tab=readme-ov-file#versioning-policy
- HCSI: https://github.com/hetznercloud/csi-driver/blob/main/docs/kubernetes/README.md#versioning-policy
- Cilium: https://github.com/cilium/cilium/blob/v1.15/Documentation/network/kubernetes/requirements.rst#kubernetes-version
- Ingress Nginx: https://github.com/kubernetes/ingress-nginx?tab=readme-ov-file#supported-versions-table 
- Cert Manager: https://cert-manager.io/docs/releases/
- Autoscaler: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/README.md#releases
-->


<!-- Roadmap -->
## :compass: Roadmap

* [ ] **Upgrade to Talos 1.8 and Kubernetes 1.31**<br>
      Once all components have compatible versions, the upgrade can be performed.
* [ ] **Integrate native IPv6 for pod traffic**<br>
      Completion requires Hetzner's addition of IPv6 support to cloud networks, expected at the beginning of 2025 as announced at Hetzner Summit 2024.

<!-- Contributing -->
## :wave: Contributing

<a href="https://github.com/hcloud-k8s/terraform-hcloud-kubernetes/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hcloud-k8s/terraform-hcloud-kubernetes" />
</a>


Contributions are always welcome!

<!-- License -->
## :balance_scale: License

Distributed under the MIT License. See [LICENSE](https://github.com/hcloud-k8s/terraform-hcloud-kubernetes/blob/main/LICENSE) for more information.

<!-- Acknowledgments -->
## :gem: Acknowledgements

- [Talos Linux](https://www.talos.dev) for its impressively secure, immutable, and minimalistic Kubernetes distribution.
- [Hetzner Cloud](https://www.hetzner.com/cloud) for offering excellent cloud infrastructure with robust Kubernetes integrations.
- Other projects like [Kube-Hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner) and [Terraform - Hcloud - Talos](https://github.com/hcloud-talos/terraform-hcloud-talos), where we’ve contributed and gained valuable insights into Kubernetes deployments on Hetzner.
