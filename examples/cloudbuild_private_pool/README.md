# Cloud Build Private Pool example
This example demonstrates how to use the [Cloud Build private pool](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/cloudbuild-private-pool) and [HA VPN](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/workerpool-gke-ha-vpn) modules to enable connectivity between Cloud Build and private GKE clusters.

## Setup
To deploy this example:

1. Run `terraform init`.

2. Create a `terraform.tfvars` to provide values for `project_id`, `primary_location` and `gke_networks`. Optionally override any variables if necessary.
See below for an example of the `gke_networks` object:
```tf
gke_networks = [
    {
        project_id = gke-dev-project-1
        location   = us-central1
        network    = gke-private-vpc-dev
        control_plane_cidrs = {
            "172.16.1.0/28" = "Dev GKE control plane"
        }
    },
    {
        project_id = gke-qa-project-1
        location   = us-central1
        network    = gke-private-vpc-qa
        control_plane_cidrs = {
            "172.16.2.0/28" = "QA GKE control plane"
        }
    },
    {
        project_id = gke-prod-project-1
        location   = us-central1
        network    = gke-private-vpc-prod
        control_plane_cidrs = {
            "172.16.3.0/28" = "Prod GKE control plane"
        }
    }
]
```
3. Modify the `vpn_config` local variable in [main.tf](./main.tf) so that the object's keys correspond to the network names specified in `var.gke_networks`.
4. Run `terraform apply`.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gke\_networks | list of GKE cluster networks in which to create VPN connections | <pre>list(object({<br>    control_plane_cidrs = map(string)<br>    location            = string<br>    network             = string<br>    project_id          = string<br>  }))</pre> | n/a | yes |
| primary\_location | Default region for resources | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| project\_id | The project to run tests against |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
