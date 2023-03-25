# Secure CI Module
This module creates a number of Google Cloud Source Repositories and a Cloud Build Trigger to facilitate a software build process with security checks.

To securely build container images, this pipeline focuses on implementing the "Securing artifacts before deployment" section of the [Shifting left on security report](https://cloud.google.com/solutions/shifting-left-on-security). The modules implements security best practices such as: using artifact repositories to store immutable container images, running container analysis scans to test container structure and check for CVEs, and signing approved images with Binary Authorization attestors to enable secure deployment.

This module creates:
* Cloud Source Repositories for: application source code, template Kubernetes manifests, and hydrated Kubernetes manifests
* Cloud Build Trigger to execute the integration pipeline upon pushing code changes to the application source code repository
* Storage Bucket to store build artifacts
* Artifact Registry repository for built container images
* Cloud KMS keyring to support attestors
* Binary Authorization attestors

## Usage
Basic usage of this module is as follows:
```hcl
module "ci_pipeline" {
  source                  = "GoogleCloudPlatform/terraform-google-secure-cicd//secure-ci"

  project_id              = var.project_id
  primary_location        = "us-central1"
  attestor_names_prefix   = ["build", "security", "quality"]
  app_build_trigger_yaml  = "cloudbuild-ci.yaml"
  runner_build_folder     = "../../../examples/app_cicd/cloud-build-builder"
  build_image_config_yaml = "cloudbuild-skaffold-build-image.yaml"
  trigger_branch_name     = ".*"
}
```
### Build Configuration
The template [`cloudbuild-ci.yaml`](../../build/cloudbuild-ci.yaml) build configuration runs container structure and vulnerability scans, and creates Binary Authorization attestations based on their results. Add the configuration file to the root of the `app_source_repo` to trigger the CI phase.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_substitutions | Parameters to be substituted in the build specification. All keys should begin with an underscore. | `map(string)` | `{}` | no |
| app\_build\_trigger\_yaml | Name of application cloudbuild yaml file | `string` | n/a | yes |
| app\_source\_repo | Name of repo that contains app source code along with cloudbuild yaml | `string` | `"app-source"` | no |
| attestor\_names\_prefix | A list of Binary Authorization attestors to create. The first attestor specified in this list will be used as the build-attestor during the CI phase. | `list(string)` | n/a | yes |
| build\_image\_config\_yaml | Name of image builder yaml file | `string` | n/a | yes |
| cache\_bucket\_name | Name of cloudbuild artifact and cache GCS bucket | `string` | `""` | no |
| cloudbuild\_cd\_repo | Name of repo that stores the Cloud Build CD phase configs - for post-deployment checks | `string` | `"cloudbuild-cd-config"` | no |
| cloudbuild\_private\_pool | Cloud Build private pool self-link | `string` | `""` | no |
| cloudbuild\_service\_account\_roles | IAM roles given to the Cloud Build service account to enable security scanning operations | `list(string)` | <pre>[<br>  "roles/artifactregistry.admin",<br>  "roles/binaryauthorization.attestorsVerifier",<br>  "roles/cloudbuild.builds.builder",<br>  "roles/clouddeploy.developer",<br>  "roles/clouddeploy.releaser",<br>  "roles/cloudkms.cryptoOperator",<br>  "roles/containeranalysis.notes.attacher",<br>  "roles/containeranalysis.notes.occurrences.viewer",<br>  "roles/source.writer",<br>  "roles/storage.admin",<br>  "roles/cloudbuild.workerPoolUser",<br>  "roles/ondemandscanning.admin",<br>  "roles/logging.logWriter"<br>]</pre> | no |
| clouddeploy\_pipeline\_name | Cloud Deploy pipeline name | `string` | `"deploy-pipeline"` | no |
| gar\_repo\_name\_suffix | Docker artifact regitery repo to store app build images | `string` | `"app-image-repo"` | no |
| labels | A set of key/value label pairs to assign to the resources deployed by this blueprint. | `map(string)` | `{}` | no |
| primary\_location | Region used for key-ring | `string` | n/a | yes |
| project\_id | Project ID for CICD Pipeline Project | `string` | n/a | yes |
| runner\_build\_folder | Path to the source folder for the cloud builds submit command. Leave blank if `skip_provisioners = true` | `string` | `""` | no |
| skip\_provisioners | Skip modules that use provisioners/local-exec | `bool` | `false` | no |
| trigger\_branch\_name | A regular expression to match one or more branches for the build trigger. | `string` | n/a | yes |
| use\_tf\_google\_credentials\_env\_var | Optional GOOGLE\_CREDENTIALS environment variable to be activated. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| app\_artifact\_repo | GAR Repo created to store runner images |
| binauth\_attestor\_ids | IDs of Attestors |
| binauth\_attestor\_names | Names of Attestors |
| binauth\_attestor\_project\_id | Project ID where attestors get created |
| build\_sa\_email | Cloud Build Service Account email address |
| build\_trigger\_name | The name of the cloud build trigger for the app source repo. |
| cache\_bucket\_name | The name of the storage bucket for cloud build. |
| source\_repo\_names | Name of the created CSR repos |
| source\_repo\_urls | URLS of the created CSR repos |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
