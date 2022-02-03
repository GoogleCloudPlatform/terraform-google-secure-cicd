# Workerpool HA VPN Module
This submodule uses the [HA VPN](https://github.com/terraform-google-modules/terraform-google-vpn/tree/master/modules/vpn_ha) module to establish a private connection between a Cloud Build worker pool VPC and a GKE VPC. Establishing connectivity through an HA VPN is necessary to enable deployment by Cloud Build to a private GKE cluster.

This module creates:
* HA VPN Gateways
* Google Cloud Routers
* Router Interfaces
* HA VPN Tunnels

## Usage

The `workerpool-gke-ha-vpn` submodule can create an HA VPN connection between the Cloud Build workerpool VPC and a single GKE VPC. The submodule can be configued for use with multiple clusters across multiple VPCs, as described in the examples below.

### Connect private pool to a single GKE cluster in single VPC
```hcl
module "gke_cloudbuild_vpn" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//workerpool-gke-ha-vpn"

  project_id = <CLOUDBUILD_WORKERPOOL_VPC_PROJECT_ID>
  location   = "us-central1"
  workerpool_network = "cloudbuild-vpc"
  workerpool_range   = "10.37.0.0/16"

  gke_project             = <GKE_VPC_PROJECT_ID>
  gke_network             = <GKE_VPC_NAME>
  gke_location            = <GKE_REGION>
  gke_control_plane_cidrs = {
      "172.16.1.0/28" = "GKE Cluster CIDR"
  }
}
```

### Connect private pool to multiple GKE clusters in single VPC
```hcl
module "gke_cloudbuild_vpn" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//workerpool-gke-ha-vpn"

  project_id = <CLOUDBUILD_WORKERPOOL_VPC_PROJECT_ID>
  location   = "us-central1"
  workerpool_network = "cloudbuild-vpc"
  workerpool_range   = "10.37.0.0/16"

  gke_project             = <GKE_NONPROD_VPC_PROJECT_ID>
  gke_network             = <GKE_NONPROD_VPC_NAME>
  gke_location            = <GKE_NONPROD_REGION>
  gke_control_plane_cidrs = {
      "172.16.1.0/28" = "GKE DEV Cluster CIDR",
      "172.16.2.0/28" = "GKE QA Cluster CIDR"
  }
}
```

### Connect private pool to multiple GKE clusters in multiple VPCs
Use the module once for each destination VPC, while maintaining non-conflicting ASNs and BGP ranges used on the VPN gateways.
```hcl
module "gke_cloudbuild_vpn_dev" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//workerpool-gke-ha-vpn"

  project_id = <CLOUDBUILD_WORKERPOOL_VPC_PROJECT_ID>
  location   = "us-central1"
  workerpool_network = "cloudbuild-vpc"
  workerpool_range   = "10.37.0.0/16"

  gke_project             = <GKE_DEV_VPC_PROJECT_ID>
  gke_network             = <GKE_DEV_VPC_NAME>
  gke_location            = <GKE_DEV_REGION>
  gke_control_plane_cidrs = {
      "172.16.1.0/28" = "GKE DEV Cluster CIDR",
  }

  gateway_1_asn = 65001
  gateway_2_asn = 65002
  bgp_range_1   = "169.254.1.0/30"
  bgp_range_2   = "169.254.2.0/30"
}

module "gke_cloudbuild_vpn_qa" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//workerpool-gke-ha-vpn"

  project_id = <CLOUDBUILD_WORKERPOOL_VPC_PROJECT_ID>
  location   = "us-central1"
  workerpool_network = "cloudbuild-vpc"
  workerpool_range   = "10.37.0.0/16"

  gke_project             = <GKE_QA_VPC_PROJECT_ID>
  gke_network             = <GKE_QA_VPC_NAME>
  gke_location            = <GKE_QA_REGION>
  gke_control_plane_cidrs = {
      "172.16.2.0/28" = "GKE QA Cluster CIDR",
  }

  gateway_1_asn = 65003
  gateway_2_asn = 65004
  bgp_range_1   = "169.254.3.0/30"
  bgp_range_2   = "169.254.4.0/30"
}

module "gke_cloudbuild_vpn_prod" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//workerpool-gke-ha-vpn"

  project_id = <CLOUDBUILD_WORKERPOOL_VPC_PROJECT_ID>
  location   = "us-central1"
  workerpool_network = "cloudbuild-vpc"
  workerpool_range   = "10.37.0.0/16"

  gke_project             = <GKE_PROD_VPC_PROJECT_ID>
  gke_network             = <GKE_PROD_VPC_NAME>
  gke_location            = <GKE_PROD_REGION>
  gke_control_plane_cidrs = {
      "172.16.3.0/28" = "GKE PROD Cluster CIDR",
  }

  gateway_1_asn = 65005
  gateway_2_asn = 65006
  bgp_range_1   = "169.254.5.0/30"
  bgp_range_2   = "169.254.6.0/30"
}
```

### Allowlist Cloud Build workerpool on GKE control plane
In the destination GKE cluster, append the Cloud Build worker pool address range to the cluster's master authorized networks to enable deployments by the private pool.

If using the [Google Kubernetes Engine module](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/private-cluster) to configure GKE, modify the `master_authorized_networks` input based on the example below:
```hcl
...
  master_authorized_networks = [
    {
      cidr_block   = "<CLOUDBUILD_CIDR>"
      display_name = "CLOUDBUILD"
    }
  ]
...
```

Otherwise, [execute a gcloud command](https://cloud.google.com/kubernetes-engine/docs/how-to/authorized-networks#add) to do so in an otherwise deployed cluster:
```sh
gcloud container clusters update CLUSTER_NAME \
    --enable-master-authorized-networks \
    --master-authorized-networks EXISTING_AUTHROIZED_CIDR_1,EXISTING_AUTHROIZED_CIDR_2,<CLOUDBUILD_CIDR>
```

### GKE Custom Routes configuraton

```hcl
resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  project = <GKE_VPC_PROJECT>
  network = <GKE_VPC_NAME>
  peering = module.gke_cluster.peering_name

  import_custom_routes = true
  export_custom_routes = true
}
```
To retrive the value of the peering connection, use the output value from the [GKE Private Cluster submodule](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/private-cluster) as shown above.

Or use a [`google_container_cluster` Data Source](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_cluster) as follows:
```hcl
data "google_container_cluster" "my_cluster" {
  project  = <GKE_PROJECT>
  name     = <GKE_CLUSTER_NAME>
  location = <GKE_LOCATION>
}

resource "google_compute_network_peering_routes_config" "gke_peering_routes_config" {
  project = <GKE_VPC_PROJECT>
  network = <GKE_VPC_NAME>
  peering = data.gogole_container_cluster.my_cluster.private_cluster_config.peering_name

  import_custom_routes = true
  export_custom_routes = true
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bgp\_range\_1 | BGP range for HA VPN tunnel 1 | `string` | `"169.254.1.0/30"` | no |
| bgp\_range\_2 | BGP range for HA VPN tunnel 1 | `string` | `"169.254.2.0/30"` | no |
| gateway\_1\_asn | ASN for HA VPN gateway #1. You can use any private ASN (64512 through 65534, 4200000000 through 4294967294) that you are not using elsewhere in your network | `number` | `65001` | no |
| gateway\_2\_asn | ASN for HA VPN gateway #2. You can use any private ASN (64512 through 65534, 4200000000 through 4294967294) that you are not using elsewhere in your network | `number` | `65002` | no |
| gke\_control\_plane\_cidrs | map of GKE control plane CIDRs to name | `map(string)` | n/a | yes |
| gke\_location | Region of GKE subnet & cluster | `string` | n/a | yes |
| gke\_network | Name of GKE VPC | `string` | n/a | yes |
| gke\_project | Project ID of GKE VPC and cluster | `string` | n/a | yes |
| location | Region for Cloud Build worker pool | `string` | `"us-central1"` | no |
| project\_id | Project ID for Cloud Build | `string` | n/a | yes |
| vpn\_router\_name\_prefix | Prefix for HA VPN router names | `string` | `""` | no |
| workerpool\_network | Self link for Cloud Build VPC | `string` | n/a | yes |
| workerpool\_range | Address range of Cloud Build Workerpool | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpn\_gateway\_cloudbuild | n/a |
| vpn\_gateway\_gke | n/a |
| vpn\_router\_cloudbuild\_names | n/a |
| vpn\_router\_gke\_names | n/a |
| vpn\_tunnel\_cloudbuild\_names | n/a |
| vpn\_tunnel\_gke\_names | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
