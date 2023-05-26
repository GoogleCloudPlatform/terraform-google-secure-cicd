# Cloud Build Private Pool Module

This submodule creates a [Cloud Build Private pool](https://cloud.google.com/build/docs/private-pools/private-pools-overview) and associated networking resources to enable deployment to private GKE clusters.

This module creates:
* Cloud Build worker pool
* Global Address
* Service Networking peering connnection
* Peering routing configuration
* Optionally, a Cloud Build VPC

## Usage

The `cloudbuild-private-pool` submodule can create a VPC for the Cloud Build worker pool, or use an existing VPC.

### Creating a standalone worker pool VPC
```hcl
module "cloudbuild_private_pool" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//cloudbuild-private-pool"

  project_id                = <PROJECT_ID>
  network_project_id        = <PROJECT_ID>
  location                  = "us-central1"
  create_cloudbuild_network = true
}
```

### Using an existing VPC
```hcl
module "cloudbuild_private_pool" {
  source = "GoogleCloudPlatform/terraform-google-secure-cicd//cloudbuild-private-pool"

  project_id                = <CLOUDBUILD_PROJECT_ID>
  network_project_id        = <VPC_PROJECT_ID>
  private_pool_vpc_name     = "existing-vpc-name"
  location                  = "us-central1"
  create_cloudbuild_network = false
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create\_cloudbuild\_network | Whether to create a VPC for the Cloud Build Worker Pool. Set to false if providing an existing VPC name in 'private\_pool\_vpc\_name' | `bool` | n/a | yes |
| labels | A set of key/value label pairs to assign to the resources deployed by this blueprint. | `map(string)` | `{}` | no |
| location | Region for Cloud Build worker pool | `string` | `"us-central1"` | no |
| machine\_type | Machine type for Cloud Build worker pool | `string` | `"e2-medium"` | no |
| network\_project\_id | Project ID for Cloud Build network. | `string` | n/a | yes |
| private\_pool\_vpc\_name | Set the name of the private pool VPC | `string` | `"cloudbuild-vpc"` | no |
| project\_id | Project ID for Cloud Build Private Worker Pool | `string` | n/a | yes |
| worker\_address | Choose an address range for the Cloud Build Private Pool workers. example: 10.37.0.0. Do not include a prefix length. | `string` | `"10.37.0.0"` | no |
| worker\_address\_prefix\_length | Prefix length, such as 24 for /24 or 16 for /16. Must be 24 or lower. | `string` | `"16"` | no |
| worker\_pool\_name | Name of Cloud Build Worker Pool | `string` | `"cloudbuild-private-worker-pool"` | no |
| worker\_pool\_no\_external\_ip | Whether to disable external IP on the Cloud Build Worker Pool | `bool` | `false` | no |
| worker\_range\_name | Name of Cloud Build Worker IP address range | `string` | `"worker-pool-range"` | no |

## Outputs

| Name | Description |
|------|-------------|
| workerpool\_id | Cloud Build worker pool ID |
| workerpool\_network | Self Link for Cloud Build workerpool VPC network |
| workerpool\_range | IP Address range for Cloud Build worker pool |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
