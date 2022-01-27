<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bgp\_range\_1 | BGP range for HA VPN tunnel 1 | `string` | `"169.254.1.0/30"` | no |
| bgp\_range\_2 | BGP range for HA VPN tunnel 1 | `string` | `"169.254.2.0/30"` | no |
| gateway\_1\_asn | ASN for HA VPN gateway #1. You can use any private ASN (64512 through 65534, 4200000000 through 4294967294) that you are not using elsewhere in your network | `number` | `65001` | no |
| gateway\_2\_asn | ASN for HA VPN gateway #2. You can use any private ASN (64512 through 65534, 4200000000 through 4294967294) that you are not using elsewhere in your network | `number` | `65002` | no |
| gke\_control\_plane\_cidrs | map of GKE control plane CIDRs to name | `map(string)` | n/a | yes |
| gke\_location | Region of GKE subnet & cluster | `string` | n/a | yes |
| gke\_network | Name of GKE VPC | `string` | n/a | yes |
| gke\_project | Project ID of GKE VPC and cluster | `string` | n/a | yes |
| location | Region for Cloud Build worker pool | `string` | `"us-central1"` | no |
| project\_id | Project ID for Cloud Build | `string` | n/a | yes |
| vpn\_router\_name\_prefix | Prefix for HA VPN router names | `string` | `""` | no |
| workerpool\_network | Self link for Cloud Build VPC | `string` | n/a | yes |
| workerpool\_range | Address range of Cloud Build Workerpool | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpn\_gateway\_cloudbuild | n/a |
| vpn\_gateway\_gke | n/a |
| vpn\_router\_cloudbuild\_names | n/a |
| vpn\_router\_gke\_names | n/a |
| vpn\_tunnel\_cloudbuild\_names | n/a |
| vpn\_tunnel\_gke\_names | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->