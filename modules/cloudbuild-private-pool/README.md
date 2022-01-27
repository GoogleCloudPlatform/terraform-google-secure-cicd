<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create\_cloudbuild\_network | Whether to create a VPC for the Cloud Build Worker Pool. Set to false if providing an existing VPC name in 'private\_pool\_vpc\_name' | `bool` | n/a | yes |
| location | Region for Cloud Build worker pool | `string` | `"us-central1"` | no |
| machine\_type | Machine type for Cloud Build worker pool | `string` | `"e2-standard-4"` | no |
| network\_project\_id | Project ID for Cloud Build network. | `string` | n/a | yes |
| private\_pool\_vpc\_name | Set the name of the private pool VPC | `string` | `"cloudbuild-vpc"` | no |
| project\_id | Project ID for Cloud Build Private Worker Pool | `string` | n/a | yes |
| worker\_address | Choose an address range for the Cloud Build Private Pool workers. example: 10.37.0.0. Do not include a prefix, as it must be /16 | `string` | `"10.37.0.0"` | no |
| worker\_pool\_name | Name of Cloud Build Worker Pool | `string` | `"cloudbuild-private-worker-pool"` | no |
| worker\_pool\_no\_external\_ip | Whether to disable external IP on the Cloud Build Worker Pool | `bool` | `true` | no |
| worker\_range\_name | Name of Cloud Build Worker IP address range | `string` | `"worker-pool-range"` | no |

## Outputs

| Name | Description |
|------|-------------|
| workerpool\_id | n/a |
| workerpool\_network | n/a |
| workerpool\_range | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->