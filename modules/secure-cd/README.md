<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_substitutions | Parameters to be substituted in the build specification. All keys should begin with an underscore. | `map(string)` | `{}` | no |
| app\_deploy\_trigger\_yaml | Name of application cloudbuild yaml file for deployment | `string` | n/a | yes |
| deploy\_branches | Branches of the Wet Manifest Repo that will trigger deployments to corresponding GKE clusters | `list(string)` | <pre>[<br>  "dev",<br>  "qa",<br>  "prod"<br>]</pre> | no |
| dev\_cluster\_name | Nane of dev cluster | `string` | n/a | yes |
| gar\_repo\_name | Docker artifact regitery repo to store app build images | `string` | n/a | yes |
| manifest\_wet\_repo | Name of repo that contains hydrated K8s manifests files | `string` | n/a | yes |
| primary\_location | Region used for key-ring | `string` | n/a | yes |
| prod\_cluster\_name | Nane of prod cluster | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |
| qa\_cluster\_name | Nane of qa cluster | `string` | n/a | yes |

## Outputs

No output.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
