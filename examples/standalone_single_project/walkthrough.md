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

1. Build a container image on which to run your Cloud Build pipeline
1. Upload Cloud Build configuration files to define the build pipeline actions
1. Push code from the Bank of Anthos demo application to your Cloud Source Repository to trigger an application build
1. View the deployed demo application

Estimated time to complete:
<walkthrough-tutorial-duration duration="25"></walkthrough-tutorial-duration>

To get started, click **Start**.

## Verify environment variables
Set the following environment variables based on your existing resources.

```
export PROJECT_ID=<YOUR PROJECT ID>
export REGION=<CLOUD REGION>
export APP_NAME=<APP NAME>
```

Run the following commands to set additional variables for the tutorial.
```bash
export GAR_REPOSITORY=$PROJECT_ID-$APP_NAME-image-repo
export CLOUDBUILD_CD_REPO=$APP_NAME-cloudbuild-cd-config
export APP_SOURCE_REPO=$APP_NAME-source
```

Click **Next**.

## Create builder image
Your Cloud Shell Terminal should already be opened to the correct directory. Verify that your current directory is `~/cloudshell_open/terraform-google-secure-cicd`. If not, click this button to open Cloud Shell:
<walkthrough-open-cloud-shell-button></walkthrough-open-cloud-shell-button>

Then, run the following command to change to the proper directory:
```bash
cd ~/cloudshell_open/terraform-google-secure-cicd
```

To build your application using Cloud Build, we will create a custom builder image that installs the necessary pacakges to build container images using **Skaffold**.

For convenience, we've pre-configured a Dockerfile to build this image. You can find it in Cloud Shell: `~/cloudshell_open/terraform-google-secure-cicd/examples/private_cluster_cicd/cloud-build-builder/Dockerfile`

1. Run the following command in Cloud Shell to build the container and store it in Artifact Registry.
    ```bash
    gcloud builds submit ./examples/private_cluster_cicd/cloud-build-builder --project $PROJECT_ID --config=./examples/private_cluster_cicd/cloud-build-builder/cloudbuild-skaffold-build-image.yaml --substitutions=_DEFAULT_REGION=$REGION,_GAR_REPOSITORY=$GAR_REPOSITORY
    ```

You will see the logs for the build process in the Cloud Shell Terminal. Once the build completes,  click **Next** to continue.

## Configure Cloud Deploy post-deployment scans
1. Change to your home directory
    ```bash
    cd ~
    ```
    Proceed with the following commands to clone the `cloudbuild-cd-config` repo.
1. Authenticate:
    ```bash
    gcloud init
    ```
1. Clone the repo:
    ```bash
    gcloud source repos clone $CLOUDBUILD_CD_REPO --project=$PROJECT_ID
    cd $CLOUDBUILD_CD_REPO
    git checkout -b main
    ```
1. Copy the Cloud Build configuration to the local repo:
    ```bash
    cp ~/cloudshell_open/terraform-google-secure-cicd/build/cloudbuild-cd.yaml ~/$CLOUDBUILD_CD_REPO/
    ```
1. Commit changes:
    ```bash
    git commit -m "initial commit"
    git push -u origin main
    ```

Click **Next**.

## Push application source code

1. Return to the home directory:
    ```bash
    cd ~
    ```
1. Clone the Bank of Anthos sample application:
    ```bash
    git clone --branch v0.5.3 https://github.com/GoogleCloudPlatform/bank-of-anthos.git
    cd bank-of-anthos
    git checkout -b main
    ```
1. Copy the Cloud Build configuration to the app-source repo
    ```bash
    cp ~/cloudshell_open/terraform-google-secure-cicd/build/cloudbuild-ci.yaml ~/bank-of-anthos/
    ```
1. Copy `policies` folder to app-source repo
    ```bash
    cp -R ~/cloudshell_open/terraform-google-secure-cicd/examples/app_cicd/policies ~/bank-of-anthos/policies
    ```
1. Push the code to the `app-source` Cloud Source Repository
    ```bash
    git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/$APP_SOURCE_REPO
    git add .
    git commit -m "initial commit"
    git push --all google
    ```

This will trigger the build phase of the CI/CD pipeline and result in the deployment of the Bank of Anthos application on GKE.

Click **Finish**.
