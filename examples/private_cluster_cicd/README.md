# Private Cluster CI/CD example

This end to end example showcases the [`secure-ci`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/secure-ci) and [`secure-cd`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/maodules/secure-cd) modules working together to create a secure software build and deploy pipeline. This example also deploys the [`cloudbuild-private-pool`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/cloudbuild-private-pool) and [`workerpool-gke-ha-vpn`](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/workerpool-gke-ha-vpn) modules to enable deploying to private GKE clusters from Cloud Build.

We will use the Bank of Anthos sample application as the target code on which to execute the CI/CD pipeline.

## Prerequisites
* GKE cluster(s) to deploy workloads, specified using the `deploy_branch_clusters` variable. See the [secure-cd module](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/tree/main/modules/secure-cd) for details on specifying the `deploy_branch_clusters` object.
* Run `gcloud auth application-default login` before following the steps below.

## Setup

To deploy this example:

### Build the infrastructure

1. Create working directory
```sh
mkdir cicd-example
cd cicd-example
```
2. Clone `secure-cicd` repo
```sh
git clone https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd.git
```
3. Run `terraform init` from within this example directory.
```sh
cd terraform-google-secure-cicd/examples/private_cluster_cicd
terraform init
```
4. Create a `terraform.tfvars` file to provide values for `project_id` and `deploy_branch_clusters` and `gke_networks` Optionally override any variables if necessary.

5. Run `terraform apply` within this example directory.

Follow steps 6 onward in the [app_cicd example instructions](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/blob/main/examples/app_cicd/README.md).

Replace step 16:

16. Copy `policies` folder to `app-source` repo
```sh
cp -R terraform-google-secure-cicd/examples/private_cluster_cicd/policies bank-of-anthos/policies
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deploy\_branch\_clusters | mapping of branch names to cluster deployments. target\_type can be one of `gke`, `anthos_cluster`, or `run`. See [clouddeploy\_target Terraform docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target) for more details | <pre>map(object({<br>    cluster               = string<br>    anthos_membership     = string<br>    project_id            = string<br>    location              = string<br>    required_attestations = list(string)<br>    env_attestation       = string<br>    next_env              = string<br>    target_type           = string<br>  }))</pre> | `{}` | no |
| gke\_networks | list of GKE cluster networks in which to create VPN connections | <pre>list(object({<br>    control_plane_cidrs = map(string)<br>    location            = string<br>    network             = string<br>    project_id          = string<br>  }))</pre> | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| binauth\_attestor\_names | Names of Attestors |
| binauth\_attestor\_project\_id | Project ID where attestors get created |
| boa\_artifact\_repo | GAR Repo created to store BoA images |
| build\_trigger\_name | The name of the cloud build trigger for the bank of anthos repo. |
| cache\_bucket\_name | The name of the storage bucket for cloud build. |
| project\_id | The project to run tests against |
| source\_repo\_names | Name of the created CSR repos |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
