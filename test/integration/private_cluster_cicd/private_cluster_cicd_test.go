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
	"fmt"
	"testing"

	// import the blueprints test framework modules for testing and assertions
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

// name the function as Test*
func TestPrivateClusterCICDExample(t *testing.T) {
	// define constants for all required assertions in the test case

	const sourceTriggerName    = "app-source-trigger"
	const garRepoNameSuffix    = "app-image-repo"
	const primaryLocation      = "us-central1"
	const appSourceRepoName    = "app-source"
	const cloudbuildCDRepoName = "cloudbuild-cd-config"

	// initialize Terraform test from the Blueprints test framework
	privateClusterCICDT := tft.NewTFBlueprintTest(t)

	// define and write a custom verifier for this test case call the default verify for confirming no additional changes
	privateClusterCICDT.DefineVerify(func(assert *assert.Assertions) {
		// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
		privateClusterCICDT.DefaultVerify(assert)

		// invoke the gcloud module in the Blueprints test framework to run a gcloud command that will output resource properties in a JSON format
		// the tft struct can be used to pull output variables of the TF module being invoked by this test and use the op object (a gjson struct)
		// to parse through the JSON results and assert the values of the resource against the constants defined above

		projectID := privateClusterCICDT.GetStringOutput("project_id")

		// Worker Pool
		workerPoolAddress := gcloud.Run(t, fmt.Sprintf("compute addresses describe private-cluster-example-worker-range --global --project %s", projectID))
		assert.Equal("10.39.0.0", workerPoolAddress.Get("address").String(), "Worker pool address range is 10.39.0.0")
		assert.Equal("INTERNAL", workerPoolAddress.Get("addressType").String(), "Worker pool address range is type INTERNAL")
		assert.Equal("VPC_PEERING", workerPoolAddress.Get("purpose").String(), "Worker pool address range is for VPC_PEERING")

		privatePoolVPC := gcloud.Run(t, fmt.Sprintf("compute networks describe gke-private-pool-example-vpc --project %s", projectID))
		assert.Contains(privatePoolVPC.Get("peerings.0.network").String(), "servicenetworking")

		privatePool := gcloud.Run(t, fmt.Sprintf("builds worker-pools describe private-cluster-example-workerpool --region=us-central1 --project %s", projectID))
		assert.Equal("RUNNING", privatePool.Get("state").String(), "Worker pool is RUNNING")

		// VPN Tunnels
		vpnTunnels := [6]string{"pc-cloudbuild-to-gke-private-vpc-dev-remote-0", "pc-cloudbuild-to-gke-private-vpc-dev-remote-1", "pc-cloudbuild-to-gke-private-vpc-prod-remote-0", "pc-cloudbuild-to-gke-private-vpc-prod-remote-1", "pc-cloudbuild-to-gke-private-vpc-qa-remote-0", "pc-cloudbuild-to-gke-private-vpc-qa-remote-1"}
		for _, tunnel := range vpnTunnels {
			tunnelStatus := gcloud.Run(t, fmt.Sprintf("compute vpn-tunnels describe %s --region=us-central1 --project %s", tunnel, projectID))
			assert.Equal("Tunnel is up and running.", tunnelStatus.Get("detailedStatus").String(), fmt.Sprintf("%s is created and running", tunnel))
		}

	})
	// call the test function to execute the integration test
	privateClusterCICDT.Test()
}
