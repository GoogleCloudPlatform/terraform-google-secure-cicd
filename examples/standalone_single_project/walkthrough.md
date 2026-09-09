<walkthrough-metadata>
  <meta name="title" content="Deploy using the secure CI/CD pipeline" />
  <meta name="description" content="Use the secure CI/CD pipeline to deploy a containerized application" />
  <meta name="component_id" content="121840" />
  <meta name="keywords" content="blueprint, CI/CD, continuous integration, continuous deployment, deployment pipeline, security development, devops, supply chain security, Cloud Build" />
</walkthrough-metadata>

# Deploy a secure CI/CD pipeline

<walkthrough-disable-features toc></walkthrough-disable-features>

![](https://walkthroughs.googleusercontent.com/content/images/intro-page.png)

## Introduction
Learn how to use your newly-deployed secure CI/CD pipeline to build and deploy containers to private GKE clusters. This tutorial describes how to do the following:

1. Configure your Terraform variables for your chosen repository provider
2. Build a container image on which to run your Cloud Build pipeline
3. Upload Cloud Build configuration files to define the build pipeline actions
4. Push code from the Bank of Anthos demo application to your chosen repository to trigger an application build
5. View the deployed demo application

Estimated time to complete:
<walkthrough-tutorial-duration duration="25"></walkthrough-tutorial-duration>

To get started, click **Start**.

## Set environment variables
1. Set your active project by running the command below, replacing `your-project-id` with the project ID where you deployed the Secure CI/CD solution:
    ```bash
    gcloud config set project your-project-id
    ```
1. Set the following environment variables. If you chose custom values when deploying the solution, replace the default values below with the values you chose.
    ```bash
    export REGION=us-central1
    export APP_NAME=ci-cd

    # Set this to "CSR", "GITHUB", or "GITLAB" depending on how you deployed the blueprint
    export REPOSITORY_TYPE="CSR"
    ```
1. Run the following commands to set additional variables for the tutorial. If you set the above values correctly, you can run this entire block without modifying it.
    ```bash
    export PROJECT_ID=$(gcloud config get project)
    export GAR_REPOSITORY=$PROJECT_ID-$APP_NAME-image-repo
    export CLOUDBUILD_CD_REPO=$APP_NAME-cloudbuild-cd-config
    export APP_SOURCE_REPO=$APP_NAME-source
    export BLUEPRINT_FOLDER=$PWD
    export WORKSPACE_FOLDER=~/workspace-$(date +%s)
    mkdir $WORKSPACE_FOLDER
    ```

Click **Next**.

## Configure Terraform Variables
Before deploying the infrastructure, you must configure the `terraform.tfvars` file to match your environment and chosen repository provider.

1. Open the `terraform.tfvars` file in your editor.
2. Replace the `{PROJECT_ID}` and `{REGION}` placeholders with your actual values.
3. **If using Cloud Source Repositories (CSR):**
   * Set `repository_type = "CSR"`
   * You can delete or comment out the `gitlab_auth`, `github_auth`, `ci_repository`, and `cd_repository` blocks.
4. **If using GitHub:**
   * Set `repository_type = "GITHUB"`
   * Provide the `github_auth` block with your Secret Manager paths for your Personal Access Token and App ID.
   * Provide the `ci_repository` and `cd_repository` blocks with your GitHub repository names and URLs.
5. **If using GitLab:**
   * Set `repository_type = "GITLAB"`
   * Provide the `gitlab_auth` block with your Secret Manager paths for your API tokens and webhook secrets.
   * Provide the `ci_repository` and `cd_repository` blocks with your GitLab repository names and URLs.

Once your `terraform.tfvars` file is configured, run `terraform init` and `terraform apply` to provision the infrastructure. Once complete, proceed to the next step.

Click **Next**.

## Configure Cloud Deploy post-deployment tests (CSR)
*If you deployed the blueprint using `REPOSITORY_TYPE="GITHUB"` or `"GITLAB"`, skip this step and proceed to the next page.*

In this step, we will configure the post-deployment by pushing a premade configuration file to the `cloudbuild-cd-config` repo in Cloud Source Repositories.
1. Set up the git configuration, replacing the values in quotes with your email address and name.
    ```bash
    git config --global user.email "name@example.com"
    git config --global user.name "Your Name"
    ```
1. Change into the workspace folder:
    ```bash
    cd $WORKSPACE_FOLDER
    ```
1. Clone the repo:
    ```bash
    gcloud source repos clone $CLOUDBUILD_CD_REPO --project=$PROJECT_ID
    cd $CLOUDBUILD_CD_REPO
    git checkout -b main
    ```
1. Copy the Cloud Build configuration to the local repo:
    ```bash
    cp $BLUEPRINT_FOLDER/build/cloudbuild-cd.yaml $WORKSPACE_FOLDER/$CLOUDBUILD_CD_REPO/
    ```
1. Commit changes:
    ```bash
    git add .
    git commit -m "initial commit"
    git push -u origin main
    ```

Click **Next**.

## Configure Cloud Deploy post-deployment tests (GitHub/GitLab)
*If you deployed the blueprint using `REPOSITORY_TYPE="CSR"`, skip this step and proceed to the next page.*

In this step, we will configure the post-deployment by pushing a premade configuration file to your linked external CD repository.
1. Set up the git configuration, replacing the values in quotes with your email address and name.
    ```bash
    git config --global user.email "name@example.com"
    git config --global user.name "Your Name"
    ```
1. Change into the workspace folder and create a directory for your CD config:
    ```bash
    cd $WORKSPACE_FOLDER
    mkdir external-cd-config
    cd external-cd-config
    ```
1. Copy the Cloud Build configuration to the local folder:
    ```bash
    cp $BLUEPRINT_FOLDER/build/cloudbuild-cd.yaml .
    ```
1. Initialize the repository and push to your external provider (replace `YOUR_REPO_URL` with the URL you provided in `cd_repository.repository_url` in your `terraform.tfvars`):
    ```bash
    git init
    git checkout -b main
    git add .
    git commit -m "Add Cloud Build CD configuration"
    git remote add origin YOUR_REPO_URL
    git push -u origin main
    ```

Click **Next**.

## Push application source code (CSR)
*If you deployed the blueprint using `REPOSITORY_TYPE="GITHUB"` or `"GITLAB"`, skip this step and proceed to the next page.*

1. Return to the workspace directory:
    ```bash
    cd $WORKSPACE_FOLDER
    ```
1. Clone the Bank of Anthos sample application:
    ```bash
    git clone --branch v0.5.11 https://github.com/GoogleCloudPlatform/bank-of-anthos.git
    cd bank-of-anthos
    git checkout -b main
    ```
1. Copy the Cloud Build configuration to the Bank of Anthos demo application folder
    ```bash
    cp $BLUEPRINT_FOLDER/build/cloudbuild-ci.yaml $WORKSPACE_FOLDER/bank-of-anthos/
    ```
1. Copy `policies` folder to the Bank of Anthos folder
    ```bash
    cp -R $BLUEPRINT_FOLDER/examples/app_cicd/policies $WORKSPACE_FOLDER/bank-of-anthos/policies
    ```
1. Push the code to the `app-source` Cloud Source Repository
    ```bash
    git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/$APP_SOURCE_REPO
    git add .
    git commit -m "initial commit"
    git push --all google
    ```

This will trigger the build phase of the CI/CD pipeline. Skip the next page and proceed directly to **View pipeline progress**.

## Push application source code (GitHub/GitLab)
*If you deployed the blueprint using `REPOSITORY_TYPE="CSR"`, you should have completed the previous steps. Skip this page.*

To use an external provider, you must push the application code and CI configuration files to the CI repository you linked during the Terraform deployment.

1. Return to the workspace directory:
    ```bash
    cd $WORKSPACE_FOLDER
    ```
2. Clone the Bank of Anthos sample application locally:
    ```bash
    git clone --branch v0.5.11 https://github.com/GoogleCloudPlatform/bank-of-anthos.git
    cd bank-of-anthos
    ```
3. Copy the required Cloud Build CI configuration and policies into the application folder:
    ```bash
    cp $BLUEPRINT_FOLDER/build/cloudbuild-ci.yaml .
    cp -R $BLUEPRINT_FOLDER/examples/app_cicd/policies ./policies
    ```
4. Initialize a new git repository and push it to your linked external CI repository (replace `YOUR_REPO_URL` with the URL you provided in `ci_repository.repository_url` in your `terraform.tfvars`):
    ```bash
    rm -rf .git
    git init
    git checkout -b main
    git add .
    git commit -m "Initial commit with Cloud Build CI configuration"
    git remote add origin YOUR_REPO_URL
    git push -u origin main
    ```

This will trigger the build phase of the CI/CD pipeline and result in the deployment of the Bank of Anthos application on GKE. The combined build and deploy phases may take up to 40 minutes to complete. To view the pipelines in-progress, click **Next**.

## View pipeline progress

1. Open the Cloud Console navigation menu, then select Cloud Build, then History
<walkthrough-menu-navigation sectionId="CLOUD_BUILD_SECTION;history"></walkthrough-menu-navigation>
1. In the <walkthrough-spotlight-pointer locator="css([jslog*='127656'])">Region</walkthrough-spotlight-pointer> selector, select your chosen region. You should see a list of builds, with a currently running build.
1. Click the build ID under the <walkthrough-spotlight-pointer locator="css([aria-label='Build'])">Build</walkthrough-spotlight-pointer> heading to view the progress of the currently running build.
1. On the Build Details page, you can see the progress of each build step in sequence. <!-- <walkthrough-spotlight-pointer locator="css([jslog*='54818'])"></walkthrough-spotlight-pointer> -->
1. You can see the output logs of the build by selecting the Build Log tab. <!-- <walkthrough-spotlight-pointer locator="css([track-name*='viewBuildLogTab'])"></walkthrough-spotlight-pointer> -->
1. When the build completes, navigate to <walkthrough-menu-navigation sectionId="CLOUD_DEPLOY_SECTION">Cloud Deploy</walkthrough-menu-navigation> to view the progress of the deployment pipeline.
1. On the Delivery pipelines page, select the pipeline in the <walkthrough-spotlight-pointer locator="css([aria-label='Delivery pipelines'])">list</walkthrough-spotlight-pointer>.
1. On the Pipeline visualization page, you can see the progress of the deployment across your 3 environments. Containers will be automatically deployed to each environment after successfully completing the security tests at each stage.

Once the application has gone through a successful rollout to all target environments, click **Next** to view the deployed application.

## View deployed application

1. Navigate to Kubernetes Engine, then Services & Ingress
<walkthrough-menu-navigation sectionId="KUBERNETES_SECTION;discovery"></walkthrough-menu-navigation>
1. Using the <walkthrough-spotlight-pointer locator="css([name='clusters'])">Clusters</walkthrough-spotlight-pointer> filter, select the checkbox for the cluster corresponding to your final environment, then press **OK**. By default, the final cluster is called "my-app-cluster-prod".
1. In the <walkthrough-spotlight-pointer locator="css([tabindex='0']).css([role='tab'])">Services</walkthrough-spotlight-pointer> tab, click the hyperlinked IP address next to the service called **frontend**. A new tab will open to the frontend service endpoint, launching the Bank of Anthos demo application.

For more information on the Bank of Anthos demo application, go the [project page on GitHub](https://github.com/GoogleCloudPlatform/bank-of-anthos)

You have now successfully deployed the Bank of Anthos demo application using the Secure CI/CD pipeline solution.

For troubleshooting deployment issues, click **Next**.

## Troubleshooting
### Org policy `constraints/compute.restrictLoadBalancerCreationForTypes` blocks creation of `frontend` service
The Bank of Anthos sample application that you'll deploy in this walkthrough requires an external load balancer for the frontend service. If you have the **Restrict load balancer types** organization policy enabled, this may block the creation of the load balancer needed.

Make sure the organization policy `constraints/compute.restrictLoadBalancerCreationForTypes` list contstraint allows the value `EXTERNAL_NETWORK_TCP_UDP`. To modify organization policies, you must have the **Organization Policy Administrator** (`roles/orgpolicy.policyAdmin`) role at the organization level.

Run the following command to make an Organization Policy at the project level to allow load balancer creation:
```bash
gcloud resource-manager org-policies allow constraints/compute.restrictLoadBalancerCreationForTypes EXTERNAL_NETWORK_TCP_UDP --project=$PROJECT_ID
