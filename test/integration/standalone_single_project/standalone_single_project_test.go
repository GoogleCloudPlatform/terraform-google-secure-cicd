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
package standalone_single_project

import (
	"testing"

	// import the blueprints test framework modules for testing and assertions
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

// name the function as Test*
func TestStandaloneSingleProjectExample(t *testing.T) {


	// initialize Terraform test from the Blueprints test framework
	setupOutput := tft.NewTFBlueprintTest(t)
	projectID := setupOutput.GetTFSetupStringOutput("project_id_standalone")

	// wire setup output project_id_standalone to example var.project_id
	standaloneSingleProjT := tft.NewTFBlueprintTest(t, tft.WithVars(map[string]interface{}{"project_id":projectID}))

	// define and write a custom verifier for this test case call the default verify for confirming no additional changes
	standaloneSingleProjT.DefineVerify(func(assert *assert.Assertions) {
		// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
		standaloneSingleProjT.DefaultVerify(assert)


	})
	// call the test function to execute the integration test
	standaloneSingleProjT.Test()
}
