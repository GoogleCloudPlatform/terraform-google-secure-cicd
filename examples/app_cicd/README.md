<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| primary\_location | Region used for key-ring | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| app\_source\_repo\_name | The name of the Cloud Source repo that contains application source code |
| bin\_auth\_attestor\_names | Names of Attestors |
| bin\_auth\_attestor\_project\_id | Project ID where attestors get created |
| boa\_artifact\_repo | GAR Repo created to store BoA images |
| build\_trigger\_name | The name of the cloud build trigger for the bank of anthos repo. |
| cache\_bucket\_name | The name of the storage bucket for cloud build. |
| dry\_manifest\_repo\_name | The name of the Cloud Source repo that contains application source code |
| project\_id | The project to run tests against |
| wet\_manifest\_repo\_name | The name of the Cloud Source repo that contains application source code |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
