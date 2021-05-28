<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_cicd\_repos | A list of Cloud Source Repos to be created to hold app infra Terraform configs | `list(string)` | n/a | yes |
| attestor\_names\_prefix | A list of Cloud Source Repos to be created to hold app infra Terraform configs | `list(string)` | n/a | yes |
| boa\_build\_repo | Name of repo that contains bank of anthos source code along with cloudbuild yaml | `string` | n/a | yes |
| build\_app\_yaml | Name of application cloudbuild yaml file | `string` | n/a | yes |
| build\_image\_yaml | Name of image builder yaml file | `string` | n/a | yes |
| gar\_repo\_name\_suffix | Docker artifact regitery repo to store app build images | `string` | n/a | yes |
| primary\_location | Region used for key-ring | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bin\_auth\_attestor\_names | Names of Attestors |
| bin\_auth\_attestor\_project\_id | Project ID where attestors get created |
| boa\_artifact\_repo | GAR Repo created to store runner images |
| build\_trigger\_name | The name of the cloud build trigger for the bank of anthos repo. |
| cache\_bucket\_name | The name of the storage bucket for cloud build. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
