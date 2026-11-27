<!--
Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# Troubleshooting Guide: Secure CI/CD Pipeline on Google Cloud Foundation

This guide provides diagnostic procedures, verification checks, and operational troubleshooting steps for common issues encountered when operating the [Secure CI/CD Pipeline](https://github.com/GoogleCloudPlatform/terraform-google-secure-cicd) deployed on top of [Terraform Example Foundation](https://cloud.google.com/architecture/security-foundations/using-example-terraform) following the instructions in [README_SECURE_CICD_FOUNDATION.md](README_SECURE_CICD_FOUNDATION.md).

---

## 1. Cloud Deploy Promotion Rejection (`Images not authorized by Binary Authorization`)

### Symptoms
When promoting a release from Development to QA, or from QA to Production, Cloud Deploy rollout fails with:
```text
admission webhook "imagepolicywebhook.image-policy.k8s.io" denied the request:
Image ... denied by Binary Authorization: Image was not signed by required attestor: projects/.../attestors/security-attestor
```

### Cause
In this architecture, promotion across environments is gated by cryptographic Binary Authorization attestations:
- **Dev Target**: Requires `build-attestor` (signed automatically by the CI build).
- **QA Target**: Requires `build-attestor` **and** `security-attestor`.
- **Prod Target**: Requires `build-attestor`, `security-attestor`, **and** `quality-attestor`.

If a release is promoted in Cloud Deploy before executing and completing the corresponding post-deployment verification trigger, the container image will lack the required signature.

### Diagnostic Procedure
1. Set common environment variables:
   ```bash
   export REGION=${REGION:-us-central1}
   export BUSINESS_CODE=${BUSINESS_CODE:-bu1}
   ```

2. Check the existing attestations on the release image:
   ```bash
   gcloud container binauthz attestations list \
     --artifact-url="<IMAGE_URL_WITH_SHA256_DIGEST>" \
     --project=${SERVICE_PROJECT_ID}
   ```
3. Verify the status of the post-deployment Cloud Build triggers:
   ```bash
   gcloud builds list --project=${SERVICE_PROJECT_ID} --region=${REGION} --limit=5
   ```

### Operational Resolution
Run the post-deployment trigger corresponding to the current environment before promoting:

- **If promoting to QA**: Execute the Dev post-deployment verification trigger (runs OWASP ZAP security scan and signs `security-attestor`):
  ```bash
  DEV_TRIGGER_ID=$(gcloud builds triggers list \
    --project=${SERVICE_PROJECT_ID} \
    --region=${REGION} \
    --filter="name:deploy-trigger-secure-app-cluster-dev-membership" \
    --format="value(id)")

  gcloud builds triggers run ${DEV_TRIGGER_ID} --project=${SERVICE_PROJECT_ID} --region=${REGION} --branch=main
  ```
  Wait until the build finishes with `SUCCESS`, then retry the QA rollout.

- **If promoting to Production**: Execute the QA post-deployment verification trigger (verifies quality metrics and signs `quality-attestor`):
  ```bash
  QA_TRIGGER_ID=$(gcloud builds triggers list \
    --project=${SERVICE_PROJECT_ID} \
    --region=${REGION} \
    --filter="name:deploy-trigger-secure-app-cluster-qa-membership" \
    --format="value(id)")

  gcloud builds triggers run ${QA_TRIGGER_ID} --project=${SERVICE_PROJECT_ID} --region=${REGION} --branch=main
  ```
  Wait until the build finishes with `SUCCESS`, then proceed with the production rollout.

---

## 2. Cloud Deploy Rollout Timeouts: Slow Cold-Starts vs Network Blocks

### Symptoms
Cloud Deploy rollout fails during the `deploy` job with:
```text
timed out waiting for the condition on deployments/balancereader
```

### Diagnostic Procedure
Determine whether the timeout is caused by normal cold-start delays or an underlying connectivity issue:

1. Connect to the target cluster via Connect Gateway:
   ```bash
   gcloud container fleet memberships get-credentials secure-app-cluster-<ENV>-membership \
     --project=${SERVICE_PROJECT_ID} \
     --billing-project=${SERVICE_PROJECT_ID}
   ```
2. Inspect the pod and node statuses:
   ```bash
   kubectl get pods,nodes -o wide
   ```

3. **Scenario A: Pods are `ContainerCreating` or `Pending` (Cold-Start Delay)**
   - **Reason**: 9 large microservice container images (Java Spring Boot, PostgreSQL) are being pulled simultaneously onto newly provisioned nodes.
   - **Remediation**: Re-run or advance the rollout once image layers are cached, or increase `progressDeadlineSeconds: 600` on the deployment manifests.

4. **Scenario B: Pods are in `CrashLoopBackOff` or Nodes are `NotReady`**
   - **Reason**: Firewall rules were not applied or were modified. Verify that the dynamic rules defined in Step 3 of the README exist on `fp-${BUSINESS_CODE}-firewalls`:
     ```bash
     gcloud compute firewall-policies rules describe 1100 --firewall-policy=fp-${BUSINESS_CODE}-firewalls --project=${SERVICE_PROJECT_ID}
     gcloud compute firewall-policies rules describe 1200 --firewall-policy=fp-${BUSINESS_CODE}-firewalls --project=${SERVICE_PROJECT_ID}
     ```
   - **Check for Dropped Egress**:
     ```bash
     gcloud logging read 'logName="projects/'${SERVICE_PROJECT_ID}'/logs/compute.googleapis.com%2Ffirewall" AND jsonPayload.disposition="DENIED"' \
       --project=${SERVICE_PROJECT_ID} \
       --limit=10
     ```

---

## 3. Terraform State Lock Contention (`Error acquiring the state lock`)

### Symptoms
Cloud Build fails during infrastructure deployment with:
```text
Error: Error acquiring the state lock
Lock Info:
  ID:        1732628492019482
  Path:      gs://bkt-prj-c-bu1-infra-pipeline-.../default.tflock
```

### Cause
Pushing changes to both the `plan` and `production` branches in close succession triggers two simultaneous Cloud Build executions against the same environment state file.

### Diagnostic & Resolution
1. Check for active running builds in the pipeline project:
   ```bash
   gcloud builds list --project=${INFRA_PIPELINE_PROJECT_ID} --region=${REGION} --filter="status=WORKING"
   ```
2. If a previous build was canceled or failed unexpectedly while holding the lock:
   ```bash
   terraform -chdir="business_unit_1/production" force-unlock <LOCK_ID>
   ```
3. **Best Practice**: In GitOps pipelines, wait for the `plan` build to finish before pushing to `production`, or push directly to `production`.

---

## 4. Connect Gateway Authentication / Permission Issues

### Symptoms
Running `kubectl` commands against GKE Fleet memberships fails with:
```text
Error from server (Forbidden): user cannot get resource ...
```
or
```text
API [connectgateway.googleapis.com] not enabled on project ...
```

### Diagnostic & Resolution
1. Ensure credentials are requested using the `--billing-project` flag:
   ```bash
   gcloud container fleet memberships get-credentials secure-app-cluster-<ENV>-membership \
     --project=${SERVICE_PROJECT_ID} \
     --billing-project=${SERVICE_PROJECT_ID}
   ```
2. Ensure your user identity or Cloud Build service account has the following IAM roles on the workload project:
   - `roles/gkehub.viewer`
   - `roles/gkehub.gatewayAdmin` (or `roles/gkehub.gatewayEditor`)
   - `roles/container.admin` (or RBAC `cluster-admin` binding on the cluster)

---

## 5. Network Connectivity Center (NCC) Spoke Routing Checks

### Symptoms
Traffic between the workload spoke VPC and other enterprise networks or the Hub is not routing.

### Diagnostic Procedure
1. Check the NCC spoke state:
   ```bash
   gcloud network-connectivity spokes list --project=${SERVICE_PROJECT_ID}
   ```
   Ensure the spoke state is `ACTIVE` (or check if it is `PENDING_REVIEW` if hub auto-accept is not enabled).

2. Inspect routes received from the NCC Hub:
   ```bash
   gcloud compute routes list \
     --project=${SERVICE_PROJECT_ID} \
     --filter="network:vpc-${BUSINESS_CODE}-secure-cicd-spoke"
   ```
