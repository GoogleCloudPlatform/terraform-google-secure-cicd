# Secure CD Module
This module creates a number of Google Cloud Build triggers to facilitate deployment of container images to GKE clusters.

To securely deploy container images, this pipeline focuses on implementing the "Securing deployed artifacts" and "Securing artifact promotions" sections of the [Shifting left on security repot](https://cloud.google.com/solutions/shifting-left-on-security). This module implements security best practices by automating the deployment and promotion of updated container images across multiple GKE clusters, and "failing fast" upon security violation. Users configure a GKE cluster's required attesttions and at which stages a container will receive that attestation based on succesful deployment. The [`cloudbuild-cd.yaml`](../../build/cloudbuild-cd.yaml) contains user-customizable post-deployment security checks to prevent promotion upon discovery of a vulnerability.

This module creates:
* [Cloud Build Triggers](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers), one for each specified deployment environment (usually one per cluster)
* A [Binary Authorization Policy](https://cloud.google.com/binary-authorization/docs) in each project with a GKE cluster, specifying which attestations are required to run containers in each cluster

## Usage
Basic usage of this module is as follows:
```hcl
module "cd_pipeline" {
  source           = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-cd"

  project_id              = var.project_id
  primary_location        = "us-central1"
  gar_repo_name           = <NAME_OF_ARTIFACT_REGISTRY_REPO>
  manifest_wet_repo       = "app-wet-manifests"
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
The template [`cloudbuild-cd.yaml`](../../build/cloudbuild-cd.yaml) build configuration deploys updated containers to specified GKE clusters upon updates to hydrated manifests in the `manifest_wet_repo`. Add the configuration file to the root of the `master` branch of the `manifest_wet_repo` to properly trigger the CD phase.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_substitutions | Parameters to be substituted in the build specification. All keys should begin with an underscore. | `map(string)` | `{}` | no |
| app\_deploy\_trigger\_yaml | Name of application cloudbuild yaml file for deployment | `string` | n/a | yes |
| cache\_bucket\_name | cloud build artifact bucket name | `string` | n/a | yes |
| cloudbuild\_private\_pool | Cloud Build private pool self-link | `string` | `""` | no |
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
