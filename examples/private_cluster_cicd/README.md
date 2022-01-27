<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deploy\_branch\_clusters | mapping of branch names to cluster deployments | <pre>map(object({<br>    cluster               = string<br>    project_id            = string<br>    location              = string<br>    required_attestations = list(string)<br>    env_attestation       = string<br>    next_env              = string<br>  }))</pre> | `{}` | no |
| gke\_networks | list of GKE cluster networks in which to create VPN connections | <pre>list(object({<br>    control_plane_cidrs = map(string)<br>    location            = string<br>    network             = string<br>    project_id          = string<br>  }))</pre> | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bin\_auth\_attestor\_names | Names of Attestors |
| bin\_auth\_attestor\_project\_id | Project ID where attestors get created |
| boa\_artifact\_repo | GAR Repo created to store BoA images |
| build\_trigger\_name | The name of the cloud build trigger for the bank of anthos repo. |
| cache\_bucket\_name | The name of the storage bucket for cloud build. |
| project\_id | The project to run tests against |
| source\_repo\_names | Name of the created CSR repos |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
