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
package private_cluster_cicd

import (
	// "fmt"
	"testing"

	// import the blueprints test framework modules for testing and assertions
	// "github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	// "github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// name the function as Test*
func TestPrivateClusterCICDExample(t *testing.T) {
	// define constants for all required assertions in the test case

	// initialize Terraform test from the Blueprints test framework
	privateClusterCICDT := tft.NewTFBlueprintTest(t)

	// define and write a custom verifier for this test case call the default verify for confirming no additional changes
	privateClusterCICDT.DefineVerify(func(assert *assert.Assertions) {
		// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
		privateClusterCICDT.DefaultVerify(assert)

		// invoke the gcloud module in the Blueprints test framework to run a gcloud command that will output resource properties in a JSON format
		// the tft struct can be used to pull output variables of the TF module being invoked by this test and use the op object (a gjson struct)
		// to parse through the JSON results and assert the values of the resource against the constants defined above

		// projectID := privateClusterCICDT.GetStringOutput("project_id")
		// gkeProjectIDs := terraform.OutputList(t, privateClusterCICDT.GetTFOptions(), "gke_project_ids")

		

	})
	// call the test function to execute the integration test
	privateClusterCICDT.Test()
}
