# Secure CD Module
This module creates a number of Google Cloud Build triggers to facilitate deployment of container images to GKE clusters.

To securely deploy container images, this pipeline focuses on implementing the "Securing deployed artifacts" and "Securing artifact promotions" sections of the [Shifting left on security report](https://cloud.google.com/solutions/shifting-left-on-security). This module implements security best practices by automating the deployment and promotion of updated container images across multiple GKE clusters, and "failing fast" upon security violation. Users configure a GKE cluster's required attesttions and at which stages a container will receive that attestation based on succesful deployment. The [`cloudbuild-cd.yaml`](../../build/cloudbuild-cd.yaml) contains user-customizable post-deployment security checks to prevent promotion upon discovery of a vulnerability.

This module creates:
* A Cloud Deploy [Pipeline and Targets](https://cloud.google.com/deploy/docs/create-pipeline-targets) for each deployment environment.
* A `clouddeploy-operations` [Pub/Sub topic](https://cloud.google.com/deploy/docs/integrating) to integrate with post-deployment processes.
* [Cloud Build Triggers](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers), to execute post-deployment checks, triggered by messages to the `clouddeploy-operations` topic.
* A [Binary Authorization Policy](https://cloud.google.com/binary-authorization/docs) in each project with a GKE cluster, specifying which attestations are required to run containers in each cluster

## Usage
Basic usage of this module is as follows:
```hcl
module "cd_pipeline" {
  source           = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-cd"

  project_id              = var.project_id
  primary_location        = "us-central1"
  gar_repo_name           = <NAME_OF_ARTIFACT_REGISTRY_REPO>
  cloudbuild_cd_repo      = "cloudbuild-cd-config-pc"
  deploy_branch_clusters  = {
    dev = {
      cluster               = "dev-cluster",
      project_id            = "gke-proj-dev",
      location              = "us-central1",
      required_attestations = ["projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/security-attestor"
      next_env              = "qa"
    },
    qa = {
      cluster               = "qa-cluster",
      project_id            = "gke-proj-prod",
      location              = "us-central1",
      required_attestations = ["projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = "projects/${var.project_id}/attestors/quality-attestor"
      next_env              = "prod"
    },
    prod = {
      cluster               = "prod-cluster",
      project_id            = "gke-proj-prod",
      location              = "us-central1",
      required_attestations = ["projects/${var.project_id}/attestors/quality-attestor", "projects/${var.project_id}/attestors/security-attestor", "projects/${var.project_id}/attestors/build-attestor"]
      env_attestation       = ""
      next_env              = ""
    },
  }
  app_deploy_trigger_yaml = "cloudbuild-cd.yaml"
  cache_bucket_name       = <NAME_OF_BUILD_ARTIFACT_BUCKET>
}
```
### Build Configuration
The template [`cloudbuild-cd.yaml`](../../build/cloudbuild-cd.yaml) build configuration specifies the post-deployment checks to run on a Cloud Deploy target upon successful deployment, triggered by Pub/Sub messages from Cloud Deploy. By default, this runs an OWASP ZAProxy scan of any exposed services. Then, the process will automatically promote the given Release to the next environment in Cloud Deploy. Push the configuration file to the root of the `main` branch of the `cloudbuild_cd_repo` to properly configure the automation.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_substitutions | Parameters to be substituted in the build specification. All keys should begin with an underscore. | `map(string)` | `{}` | no |
| app\_deploy\_trigger\_yaml | Name of application cloudbuild yaml file for deployment | `string` | n/a | yes |
| cache\_bucket\_name | cloud build artifact bucket name | `string` | n/a | yes |
| cloudbuild\_cd\_repo | Name of repo that stores the Cloud Build CD phase configs - for post-deployment checks | `string` | n/a | yes |
| cloudbuild\_private\_pool | Cloud Build private pool self-link | `string` | `""` | no |
| cloudbuild\_service\_account | Cloud Build SA email address | `string` | n/a | yes |
| clouddeploy\_pipeline\_name | Cloud Deploy pipeline name | `string` | n/a | yes |
| deploy\_branch\_clusters | mapping of branch names to cluster deployments. target\_type can be one of `gke`, `anthos_cluster`, or `run`. See [clouddeploy\_target Terraform docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target) for more details | <pre>map(object({<br>    cluster               = string<br>    anthos_membership     = string<br>    project_id            = string<br>    location              = string<br>    required_attestations = list(string)<br>    env_attestation       = string<br>    next_env              = string<br>    target_type           = string<br>  }))</pre> | `{}` | no |
| gar\_repo\_name | Docker artifact registry repo to store app build images | `string` | n/a | yes |
| labels | A set of key/value label pairs to assign to the resources deployed by this blueprint. | `map(string)` | `{}` | no |
| primary\_location | Region used for key-ring | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| binauthz\_policy\_required\_attestations | Binary Authorization policy required attestation in GKE projects |
| clouddeploy\_delivery\_pipeline\_id | ID of the Cloud Deploy delivery pipeline |
| clouddeploy\_target\_id | ID(s) of Cloud Deploy targets |
| deploy\_trigger\_names | Names of CD Cloud Build triggers |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
