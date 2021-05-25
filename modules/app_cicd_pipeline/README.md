<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_cicd\_build\_sa | Service account email of the account to impersonate to run Terraform | `string` | n/a | yes |
| app\_cicd\_project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |
| app\_cicd\_repos | A list of Cloud Source Repos to be created to hold app infra Terraform configs | `list(string)` | <pre>[<br>  "bank-of-anthos-source",<br>  "root-config-repo",<br>  "accounts",<br>  "transactions",<br>  "frontend"<br>]</pre> | no |
| attestor\_names\_prefix | A list of Cloud Source Repos to be created to hold app infra Terraform configs | `list(string)` | <pre>[<br>  "build",<br>  "quality",<br>  "security"<br>]</pre> | no |
| boa\_build\_repo | Name of repo that contains bank of anthos source code along with cloudbuild yaml | `string` | `"bank-of-anthos-source"` | no |
| build\_app\_yaml | Name of application cloudbuild yaml file | `string` | `"cloudbuild-build-boa.yaml"` | no |
| build\_image\_yaml | Name of image builder yaml file | `string` | `"cloudbuild-build-boa.yaml"` | no |
| gar\_repo\_name\_suffix | Docker artifact regitery repo to store app build images | `string` | `"boa-image-repo"` | no |
| primary\_location | Region used for key-ring | `string` | `"us-east1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| bin\_auth\_attestor\_names | Names of Attestors |
| bin\_auth\_attestor\_project\_id | Project ID where attestors get created |
| boa\_artifact\_repo | GAR Repo created to store runner images |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
