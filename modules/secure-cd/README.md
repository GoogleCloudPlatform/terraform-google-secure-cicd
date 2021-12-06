<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_substitutions | Parameters to be substituted in the build specification. All keys should begin with an underscore. | `map(string)` | `{}` | no |
| app\_deploy\_trigger\_yaml | Name of application cloudbuild yaml file for deployment | `string` | n/a | yes |
| cache\_bucket\_name | cloud build artifact bucket name | `string` | n/a | yes |
| deploy\_branch\_clusters | mapping of branch names to cluster deployments | <pre>map(object({<br>    cluster               = string<br>    project_id            = string<br>    location              = string<br>    required_attestations = list(string)<br>    env_attestation       = string<br>    next_env              = string<br>  }))</pre> | `{}` | no |
| gar\_repo\_name | Docker artifact registry repo to store app build images | `string` | n/a | yes |
| manifest\_wet\_repo | Name of repo that contains hydrated K8s manifests files | `string` | n/a | yes |
| primary\_location | Region used for key-ring | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| binauthz\_policy\_required\_attestations | Binary Authorization policy required attestation in GKE projects |
| deploy\_trigger\_names | Names of CD Cloud Build triggers |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
