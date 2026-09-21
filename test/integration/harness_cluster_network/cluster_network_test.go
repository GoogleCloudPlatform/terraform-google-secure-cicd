// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package harness_cluster_network

import (
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/terraform-google-modules/terraform-google-secure-cicd/test/integration/testutils"
)

func TestClusterNetwork(t *testing.T) {
	setupOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup"))

	projectID := setupOutput.GetStringOutput("project_id_standalone")
	region := setupOutput.GetStringOutput("primary_location")

	vars := map[string]interface{}{
		"project_id": projectID,
		"region":     region,
	}
	clusterNetworkPath := "../../setup/harness/cluster_network"

	clusterNetwork := tft.NewTFBlueprintTest(t,
		tft.WithTFDir(clusterNetworkPath),
		tft.WithVars(vars),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
		tft.WithParallelism(100),
	)
	clusterNetwork.Test()
}
