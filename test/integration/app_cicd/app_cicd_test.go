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
	"github.com/stretchr/testify/assert"
)

// name the function as Test*
func TestAppCICDExample(t *testing.T) {
	// define constants for all required assertions in the test case

	const triggerName       = "app-source-trigger"
	const garRepoNameSuffix = "app-image-repo"
	const primaryLocation   = "us-central1"
	const appSourceRepoName = "app-source"
	const manifestDryRepoName = "app-dry-manifests"
	const manifestWetRepoName = "app-wet-manifests"

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

		// Cloud Build Trigger - App Source
		gcb := gcloud.Run(t, fmt.Sprintf("beta builds triggers describe %s --project %s", triggerName, projectID))

		assert.Equal(triggerName, gcb.Get("name").String(), "Cloud Build Trigger name is valid")
		assert.Equal(manifestDryRepoName, gcb.Get("substitutions._MANIFEST_DRY_REPO").String(), "Manifest Dry Repo trigger substitution is valid")
		assert.Equal(manifestWetRepoName, gcb.Get("substitutions._MANIFEST_WET_REPO").String(), "Manifest Wet Repo trigger substitution is valid")
		assert.Contains(gcb.Get("substitutions._DEFAULT_REGION").String(), primaryLocation, "Default Region trigger substitution is valid")
		assert.Equal(appSourceRepoName, gcb.Get("triggerTemplate.repoName").String(), "Attached CSR repo is valid")

		// Artifact Registry repository
		gar := gcloud.Run(t, fmt.Sprintf("artifacts repositories describe %s-%s --project %s --location %s", projectID, garRepoNameSuffix, projectID, primaryLocation))
		garFullname := "projects/" + projectID + "/locations/" + primaryLocation + "/repositories/" + projectID + "-" + garRepoNameSuffix
		assert.Equal(garFullname, gar.Get("name").String(), "GAR Repo is valid")

		// TODO: BinAuthz

		// TODO: CSR
		csrSource := gcloud.Run(t, fmt.Sprintf("source repos describe %s --project %s", appSourceRepoName, projectID))
		csrDryManifest := gcloud.Run(t, fmt.Sprintf("source repos describe %s --project %s", manifestDryRepoName, projectID))
		csrWetManifest := gcloud.Run(t, fmt.Sprintf("source repos describe %s --project %s", manifestWetRepoName, projectID))
		
		csrSourceFullName := "projects/" + projectID + "/repos/" + appSourceRepoName
		csrDryManifestFullName := "projects/" + projectID + "/repos/" + manifestDryRepoName
		csrWetManifestFullName := "projects/" + projectID + "/repos/" + manifestWetRepoName

		csrSourceURL := "https://source.developers.google.com/p/" + projectID + "/r/" + appSourceRepoName
		csrDryManifestURL := "https://source.developers.google.com/p/" + projectID + "/r/" + manifestDryRepoName
		csrWetManifestURL := "https://source.developers.google.com/p/" + projectID + "/r/" + manifestWetRepoName

		assert.Equal(csrSourceFullName, csrSource.Get("name").String(), "CSR App Source repo name is valid")
		assert.Equal(csrDryManifestFullName, csrDryManifest.Get("name").String(), "CSR Dry Manifest repo name is valid")
		assert.Equal(csrWetManifestFullName, csrWetManifest.Get("name").String(), "CSR Wet Manifest repo name is valid")

		assert.Equal(csrSourceURL, csrSource.Get("url").String(), "CSR App Source URL is valid")
		assert.Equal(csrDryManifestURL, csrDryManifest.Get("url").String(), "CSR Dry Manifest URL is valid")
		assert.Equal(csrWetManifestURL, csrWetManifest.Get("url").String(), "CSR Wet Manifest URL is valid")



	})
	// call the test function to execute the integration test
	appCICDT.Test()
}
