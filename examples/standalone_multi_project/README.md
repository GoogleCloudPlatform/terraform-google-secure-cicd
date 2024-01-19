# Standalone Multi Project CI/CD example

This end to end example showcases the [`secure-ci`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/secure-ci) and [`secure-cd`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/maodules/secure-cd) modules working together to create a secure software build and deploy pipeline, which is able to deploy to target environments in multiple projects. This example also deploys the [`cloudbuild-private-pool`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/cloudbuild-private-pool) and [`workerpool-gke-ha-vpn`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/workerpool-gke-ha-vpn) modules to enable deploying to private GKE clusters from Cloud Build.

This example also creates GKE clusters and accompanying VPC networks for sample target environments in multiple separate projects for simplified deployment and demonstration purposes.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | Name of intended deployed application; to be used as a prefix for certain resources | `string` | `"my-app"` | no |
| cloudbuild\_private\_pool\_machine\_type | Machine type for Cloud Build private pool | `string` | `"e2-medium"` | no |
| env1\_name | Name of environment 1 | `string` | `"dev"` | no |
| env1\_project\_id | Environment 1 project ID | `string` | n/a | yes |
| env2\_name | Name of environment 2 | `string` | `"qa"` | no |
| env2\_project\_id | Environment 2 project ID | `string` | n/a | yes |
| env3\_name | Name of environment 3 | `string` | `"prod"` | no |
| env3\_project\_id | Environment 3 project ID | `string` | n/a | yes |
| labels | A set of key/value label pairs to assign to the resources deployed by this blueprint. | `map(string)` | `{}` | no |
| management\_name | Name of management environment | `string` | `"mgmt"` | no |
| management\_project\_id | Management project ID | `string` | n/a | yes |
| region | Location in which all regional resources will be deployed | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_source\_repo | URL of the created CSR app soure repo |
| cloudbuild\_cd\_repo\_name | URL of the created CSR app soure repo |
| console\_walkthrough\_link | URL to open the in-console walkthrough. |
| gar\_repo | Artifact Registry repo |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->