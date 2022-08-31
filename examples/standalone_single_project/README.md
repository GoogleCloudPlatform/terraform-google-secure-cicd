<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | Name of intended deployed application; to be used as a prefix for certain resources | `string` | `"my-app"` | no |
| env1\_name | Name of environment 1 | `string` | `"dev"` | no |
| env2\_name | Name of environment 2 | `string` | `"qa"` | no |
| env3\_name | Name of environment 3 | `string` | `"prod"` | no |
| project\_id\_standalone | Project ID in which all resources will be deployed | `string` | n/a | yes |
| region | Location in which all regional resources will be deployed | `string` | `"us-central1"` | no |

## Outputs

No output.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
