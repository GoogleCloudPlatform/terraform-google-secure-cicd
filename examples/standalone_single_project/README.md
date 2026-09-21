# Standalone Single Project CI/CD example

This end-to-end example showcases the [`secure-ci`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/secure-ci) and [`secure-cd`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/secure-cd) modules working together to create a secure software build and deploy pipeline.

This example also deploys the [`cloudbuild-private-pool`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/cloudbuild-private-pool) module to enable deploying to private GKE clusters from Cloud Build.

For simplified deployment and demonstration purposes, this blueprint creates GKE clusters and accompanying VPC networks for multiple sample environments (dev, qa, prod) within a single Google Cloud project.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_level\_name | (VPC-SC) Access Level full name. When providing this variable, additional identities will be added to the access level, these are required to work within an enforced VPC-SC Perimeter. | `string` | `null` | no |
| app\_name | Name of intended deployed application; to be used as a prefix for certain resources | `string` | `"ci-cd"` | no |
| cd\_repository | The CD repository to configure. The key is a short name for the service. | <pre>object({<br>    repository_name = string<br>    repository_url  = string<br>  })</pre> | `null` | no |
| ci\_repository | The CI repository to configure. The key is a short name for the service. | <pre>object({<br>    repository_name = string<br>    repository_url  = string<br>  })</pre> | `null` | no |
| cloudbuild\_private\_pool\_machine\_type | Machine type for Cloud Build private pool | `string` | `"e2-medium"` | no |
| env1\_name | Name of environment 1 | `string` | `"dev"` | no |
| env2\_name | Name of environment 2 | `string` | `"qa"` | no |
| env3\_name | Name of environment 3 | `string` | `"prod"` | no |
| github\_auth | Authentication configuration for GitHub. Required only if repo\_type is 'GITHUBv2'. | <pre>object({<br>    secret_id         = string<br>    app_id_secret_id  = string<br>    secret_project_id = string<br>  })</pre> | `null` | no |
| gitlab\_auth | Authentication configuration for GitLab. Required only if repo\_type is 'GITLABv2'. | <pre>object({<br>    read_authorizer_credential_secret_id = string<br>    authorizer_credential_secret_id      = string<br>    webhook_secret_id                    = string<br>    enterprise_host_uri                  = optional(string)<br>    enterprise_service_directory         = optional(string)<br>    enterprise_ca_certificate            = optional(string)<br>    secret_project_id                    = string<br>  })</pre> | `null` | no |
| labels | A set of key/value label pairs to assign to the resources deployed by this blueprint. | `map(string)` | `{}` | no |
| network\_name | Optional vpc network name if using already existing vpc | `any` | `null` | no |
| private\_worker\_pool\_id | Optional private worker pool id if using already existing worker pool | `any` | n/a | yes |
| project\_id | Project ID in which all resources will be deployed | `string` | n/a | yes |
| region | Location in which all regional resources will be deployed | `string` | `"us-central1"` | no |
| repository\_type | Repository type, e.g. GITHUB or GITLAB | `string` | `"GITLAB"` | no |

## Outputs

| Name | Description |
|------|-------------|
| attestors | Map of Binary Authorization attestor IDs by name |
| cd\_ordered\_trigger\_names | Names of CD Cloud Build triggers in promotion order |
| cd\_repo\_name | Name of the CD source repository |
| cd\_repo\_url | The URL of the CD repository. |
| ci\_build\_trigger\_id | ID of the CI Cloud Build trigger |
| ci\_repo\_name | Name of the CI source repository |
| ci\_repo\_url | The URL of the CI repository. |
| ci\_service\_account | Service account created and used during the CI infra deployment |
| cloudbuild\_workerpool\_id | ID of the Cloud Build private worker pool |
| clouddeploy\_pipeline\_id | ID of the Cloud Deploy delivery pipeline |
| clouddeploy\_target\_ids | ID(s) of Cloud Deploy targets |
| clouddeploy\_target\_names\_ordered | Names of Cloud Deploy targets in promotion order |
| cluster\_membership\_ids | GKE cluster membership IDs. |
| gar\_repo\_name | Name of the Google Artifact Registry repository |
| gitlab\_url | The URL of the GitLab instance. |
| gke\_cluster\_names | Map of GKE Cluster names by environment |
| project\_id | Project ID in which all resources were deployed |
| region | Region in which all regional resources were deployed |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
