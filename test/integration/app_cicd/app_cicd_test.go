/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// define test package name
package app_cicd

import (
	"fmt"
	"testing"

	// import the blueprints test framework modules for testing and assertions
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// name the function as Test*
func TestAppCICDExample(t *testing.T) {
	// define constants for all required assertions in the test case

	const sourceTriggerName    = "app-source-trigger"
	const garRepoNameSuffix    = "app-image-repo"
	const primaryLocation      = "us-central1"
	const appSourceRepoName    = "app-source"
	const cloudbuildCDRepoName = "cloudbuild-cd-config"

	// initialize Terraform test from the Blueprints test framework
	appCICDT := tft.NewTFBlueprintTest(t)

	// define and write a custom verifier for this test case call the default verify for confirming no additional changes
	appCICDT.DefineVerify(func(assert *assert.Assertions) {
		// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
		appCICDT.DefaultVerify(assert)

		// invoke the gcloud module in the Blueprints test framework to run a gcloud command that will output resource properties in a JSON format
		// the tft struct can be used to pull output variables of the TF module being invoked by this test and use the op object (a gjson struct)
		// to parse through the JSON results and assert the values of the resource against the constants defined above

		projectID := appCICDT.GetStringOutput("project_id")
		gkeProjectIDs := terraform.OutputList(t, appCICDT.GetTFOptions(), "gke_project_ids")

		/////// SECURE-CI ///////
		// Cloud Build Trigger - App Source
		gcbCI := gcloud.Run(t, fmt.Sprintf("builds triggers describe %s --project %s --region %s", sourceTriggerName, projectID, primaryLocation))

		assert.Equal(sourceTriggerName, gcbCI.Get("name").String(), "Cloud Build Trigger name is valid")
		assert.Contains(gcbCI.Get("substitutions._DEFAULT_REGION").String(), primaryLocation, "Default Region trigger substitution is valid")
		assert.Equal(appSourceRepoName, gcbCI.Get("triggerTemplate.repoName").String(), "Attached CSR repo is valid")

		// Artifact Registry repository
		gar := gcloud.Run(t, fmt.Sprintf("artifacts repositories describe %s-%s --project %s --location %s", projectID, garRepoNameSuffix, projectID, primaryLocation))
		garFullname := fmt.Sprintf("projects/%s/locations/%s/repositories/%s-%s", projectID, primaryLocation, projectID, garRepoNameSuffix)
		assert.Equal(garFullname, gar.Get("name").String(), "GAR Repo is valid")

		// BinAuthz Attestors
		attestors := [3]string{"build-attestor", "quality-attestor", "security-attestor"}

		for _, attestor := range attestors {
			binAuthZAttestor := gcloud.Run(t, fmt.Sprintf("container binauthz attestors describe %s --project %s", attestor, projectID))
			attestorFullName := fmt.Sprintf("projects/%s/attestors/%s", projectID, attestor)
			assert.Equal(attestorFullName, binAuthZAttestor.Get("name").String(), fmt.Sprintf("%s is valid", attestor))
		}

		// CSR
		repos := [2]string{appSourceRepoName, cloudbuildCDRepoName}

		for _, repo := range repos {
			csr := gcloud.Run(t, fmt.Sprintf("source repos describe %s --project %s", repo, projectID))
			csrFullName := fmt.Sprintf("projects/%s/repos/%s", projectID, repo)
			csrURL := fmt.Sprintf("https://source.developers.google.com/p/%s/r/%s", projectID, repo)
			assert.Equal(csrFullName, csr.Get("name").String(), fmt.Sprintf("CSR %s repo name is valid", repo))
			assert.Equal(csrURL, csr.Get("url").String(), fmt.Sprintf("CSR %s URL is valid", repo))
		}

		/////// SECURE-CD ///////
		// Deploy Triggers
		cdTriggers := [2]string{"deploy-trigger-dev-cluster", "deploy-trigger-qa-cluster"}

		for _, cdTrigger := range cdTriggers {
			gcbCD := gcloud.Run(t, fmt.Sprintf("builds triggers describe %s --project %s --region %s", cdTrigger, projectID, primaryLocation))
			assert.Contains(gcbCD.Get("name").String(), cdTrigger, "Trigger name is valid")
			assert.Contains(gcbCD.Get("pubsubConfig.topic").String(), "clouddeploy-operations", "pubsub topic is valid")
			assert.Contains(gcbCD.Get("substitutions._CLUSTER_PROJECT").String(), "secure-cicd-gke-", "_CLUSTER_PROJECT trigger substitution is valid")
		}

		// BinAuthz Policy
		for _, gkeProjectID := range gkeProjectIDs {
			binAuthZPolicy := gcloud.Run(t, fmt.Sprintf("container binauthz policy export --project %s", gkeProjectID))
			cluster := gcloud.Run(t, fmt.Sprintf("container clusters list --project %s", gkeProjectID))
			clusterName := cluster.Get("0.name").String()
			assert.Contains(binAuthZPolicy.Get("defaultAdmissionRule.enforcementMode").String(), "ENFORCED_BLOCK_AND_AUDIT_LOG")
			assert.Contains(binAuthZPolicy.Get("defaultAdmissionRule.evaluationMode").String(), "ALWAYS_DENY")
			assert.Contains(binAuthZPolicy.Get(fmt.Sprintf("clusterAdmissionRules.us-central1\\.%s.evaluationMode", clusterName)).String(), "REQUIRE_ATTESTATION")
			assert.Contains(binAuthZPolicy.Get(fmt.Sprintf("clusterAdmissionRules.us-central1\\.%s.requireAttestationsBy", clusterName)).String(), "build-attestor")

			switch clusterName {
			case "qa-cluster":
				assert.Contains(binAuthZPolicy.Get(fmt.Sprintf("clusterAdmissionRules.us-central1\\.%s.requireAttestationsBy", clusterName)).String(), "security-attestor")
			case "prod-cluster":
				assert.Contains(binAuthZPolicy.Get(fmt.Sprintf("clusterAdmissionRules.us-central1\\.%s.requireAttestationsBy", clusterName)).String(), "security-attestor")
				assert.Contains(binAuthZPolicy.Get(fmt.Sprintf("clusterAdmissionRules.us-central1\\.%s.requireAttestationsBy", clusterName)).String(), "quality-attestor")
			}
		}

	})
	// call the test function to execute the integration test
	appCICDT.Test()
}
