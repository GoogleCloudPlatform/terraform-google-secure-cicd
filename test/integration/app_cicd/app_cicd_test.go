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

	const app_source_repo      = "app-source"
	const trigger_name         = "app-source-trigger"
	const manifest_dry_repo    = "app-dry-manifests"
	const manifest_wet_repo    = "app-wet-manifests"
	const gar_repo_name_suffix = "app-image-repo"
	const primary_location     = "us-central1"

	// initialize Terraform test from the Blueprints test framework
	appCICDT := tft.NewTFBlueprintTest(t)

	// define and write a custom verifier for this test case call the default verify for confirming no additional changes
	appCICDT.DefineVerify(func(assert *assert.Assertions) {
		// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
		appCICDT.DefaultVerify(assert)

		// invoke the gcloud module in the Blueprints test framework to run a gcloud command that will output resource properties in a JSON format
		// the tft struct can be used to pull output variables of the TF module being invoked by this test and use the op object (a gjson struct)
		// to parse through the JSON results and assert the values of the resource against the constants defined above

		// Cloud Build Trigger - App Source
		gcb := gcloud.Run(t, fmt.Sprintf("beta builds triggers describe %s --project %s", trigger_name, appCICDT.GetStringOutput("project_id")))

		assert.Equal(trigger_name, gcb.Get("name").String(), "Cloud Build Trigger name is valid")
		assert.Equal(manifest_dry_repo, gcb.Get("substitutions._MANIFEST_DRY_REPO").String(), "Manifest Dry Repo trigger substitution is valid")
		assert.Equal(manifest_wet_repo, gcb.Get("substitutions._MANIFEST_WET_REPO").String(), "Manifest Wet Repo trigger substitution is valid")
		assert.Contains(gcb.Get("substitutions._DEFAULT_REGION").String(), primary_location, "Default Region trigger substitution is valid")
		assert.Equal(app_source_repo, gcb.Get("triggerTemplate.repoName").String(), "Attached CSR repo is valid")

		// Artifact Registry repository
		gar := gcloud.Run(t, fmt.Sprintf("artifacts repositories describe %s-%s --project %s --location %s", appCICDT.GetStringOutput("project_id"), gar_repo_name_suffix, appCICDT.GetStringOutput("project_id"), primary_location))
		gar_fullname := "projects/" + appCICDT.GetStringOutput("project_id") + "/locations/" + primary_location + "/repositories/" + appCICDT.GetStringOutput("project_id") + "-" + gar_repo_name_suffix
		assert.Equal(gar_fullname, gar.Get("name").String(), "GAR Repo is valid")

		// TODO: BinAuthz
	})
	// call the test function to execute the integration test
	appCICDT.Test()
}
