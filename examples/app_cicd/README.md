# App CI/CD example

This end to end example showcases the `secure-ci` and `secure-cd` modules working together to create a secure software build and deploy pipeline.

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
1. Clone `secure-cicd` repo
```sh
git clone https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd.git
```
1. Run `terraform init` to enable the proper APIs.
```sh
cd terraform-google-secure-cicd/examples/app_cicd/configure-project
terraform init
```
1. Create a `terraform.tfvars` file to provide values for `project_id`.
1. Run `terraform apply` to enable the proper APIs.
1. Run `terraform init` from within this example directory.
```sh
cd terraform-google-secure-cicd/examples/app_cicd
terraform init
```
1. Create a `terraform.tfvars` file to provide values for `project_id` and `deploy_branch_clusters`. Optionally override any variables if necessary.
1. Run `terraform apply` within this example directory.

### Sample application configuration
1. Export CI/CD project ID
```sh
export PROJECT_ID=<CICD Project ID>
```
1. Return to working directory
```sh
cd ../../..
```
1. Clone the Bank of Anthos sample application repo
```sh
git clone --branch v0.5.3 https://github.com/GoogleCloudPlatform/bank-of-anthos.git
```
1. Clone the `app-dry-manifests` repo
```sh
gcloud source repos clone app-dry-manifests --project=$PROJECT_ID
```
1. Copy the Bank of Anthos Kubernetes manifests to the `app-dry-manifests` repo
```sh
cp bank-of-anthos/dev-kubernetes-manifests/* app-dry-manifests/
```
1. Copy the Skaffold config to the `app-dry-manifests` repo
```sh
cp bank-of-anthos/skaffold.yaml app-dry-manifests/
```
1. Replace Skaffold manifest paths with repo path
```sh
sed -i 's/dev-kubernetes-manifests/app-dry-manifests/g' app-dry-manifests/skaffold.yaml
```
1. Push `app-dry-manifests` changes
```sh
cd app-dry-manifests/
git add .
git commit -m "initial commit"
git push
cd ..
```

1. Copy `cloudbuild-ci.yaml` to `app-source` repo
```sh
cp terraform-google-secure-cicd/build/cloudbuild-ci.yaml bank-of-anthos/
```
1. Copy `policies` folder to `app-source` repo
```sh
cp -R terraform-google-secure-cicd/examples/app_cicd/policies bank-of-anthos/policies
```

1. Add `app-source` repo as new remote for Bank of Anthos source code and push
```sh
cd bank-of-anthos
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/app-source
git push --all google
```
1. Return to working directory
```sh
cd ..
```
1. Clone `app-wet-manifests` repo
```sh
gcloud source repos clone app-wet-manifests --project=$PROJECT_ID
```

1. Copy `cloudbuild-cd.yaml` to `app-wet-manifests` repo
```sh
cp terraform-google-secure-cicd/build/cloudbuild-cd.yaml app-wet-manifests/
```
1. Push changes in `app-wet-manifests` repo
```sh
cd app-wet-manifests
git add .
git commit -m "initial config commit"
git push
```
## Troubleshooting
### Container Structure Test
Default checks in the `container-structure-test` step of the CI phase may fail on some containers. To ignore the violations and pass the checks for demonstration purposes, comment out the violated policies defined in the [policies/container-structure-policy.yaml](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd/blob/main/examples/app_cicd/policies/container-structure-policy.yaml) file and push the changes to the `app-source` repo, triggering a new build.

### Deploying from Cloud Shell
Sometimes when running Terraform from Google Cloud Shell, the system may encounter the following error or similar:
```
dial tcp [IP_V6_ADDRESS]:443: connect: cannot assign requested address
```
This is a [known issue](https://github.com/hashicorp/terraform-provider-google/issues/6782) addressed in the Google Terraform provider open source issues.

Run [this command](https://github.com/hashicorp/terraform-provider-google/issues/6782#issuecomment-874574409) in Cloud Shell as a workaround:
```sh
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1 net.ipv6.conf.lo.disable_ipv6=1 > /dev/null
export APIS="googleapis.com www.googleapis.com storage.googleapis.com iam.googleapis.com container.googleapis.com cloudresourcemanager.googleapis.com"
for name in $APIS
do
    ipv4=$(getent ahostsv4 "$name" | head -n 1 | awk '{ print $1 }')
    grep -q "$name" /etc/hosts || ([ -n "$ipv4" ] && sudo sh -c "echo '$ipv4 $name' >> /etc/hosts")
done
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deploy\_branch\_clusters | mapping of branch names to cluster deployments | <pre>map(object({<br>    cluster               = string<br>    project_id            = string<br>    location              = string<br>    required_attestations = list(string)<br>    env_attestation       = string<br>    next_env              = string<br>  }))</pre> | `{}` | no |
| primary\_location | Region used for key-ring | `string` | `"us-central1"` | no |
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
