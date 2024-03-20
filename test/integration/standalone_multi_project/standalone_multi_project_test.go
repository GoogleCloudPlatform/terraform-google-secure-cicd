/**
 * Copyright 2023 Google LLC
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
package standalone_multi_project

import (
	"fmt"
	"testing"
	"time"

	// import the blueprints test framework modules for testing and assertions
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/git"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"

	cp "github.com/otiai10/copy"
)

// name the function as Test*
func TestStandaloneMultiProjectExample(t *testing.T) {

	// initialize Terraform test from the Blueprints test framework
	setupOutput := tft.NewTFBlueprintTest(t)
	mgmtProjectID := setupOutput.GetTFSetupStringOutput("project_id_standalone_multi")
	gkeProjectIDs := setupOutput.GetTFSetupOutputListVal("gke_project_ids_standalone_multi")

	// wire setup outputs to the Terraform inputs for the standalone multi project example
	standaloneMultiProjT := tft.NewTFBlueprintTest(t, tft.WithVars(map[string]interface{}{"management_project_id": mgmtProjectID, "env1_project_id": gkeProjectIDs[0], "env2_project_id": gkeProjectIDs[1], "env3_project_id": gkeProjectIDs[2]}))

	// define and write a custom verifier for this test case call the default verify for confirming no additional changes
	standaloneMultiProjT.DefineVerify(func(assert *assert.Assertions) {
		// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
		standaloneMultiProjT.DefaultVerify(assert)

		garRepo := standaloneMultiProjT.GetStringOutput("gar_repo")
		appRepo := fmt.Sprintf("https://source.developers.google.com/p/%s/r/my-app-source", mgmtProjectID)
		cdRepo := standaloneMultiProjT.GetStringOutput("cloudbuild_cd_repo_name")
		region := "us-central1"
		pipelineName := "my-app-pipeline"
		prodTarget := "my-app-cluster-prod-target"

		// Create Builder image
		gcloud.RunCmd(t, fmt.Sprintf("builds submit ../../../examples/private_cluster_cicd/cloud-build-builder --project %s --region %s --config=../../../examples/private_cluster_cicd/cloud-build-builder/cloudbuild-skaffold-build-image.yaml --substitutions=_DEFAULT_REGION=%s,_GAR_REPOSITORY=%s", mgmtProjectID, region, region, garRepo))

		// Configure Cloud Deploy post-deployment scans
		tmpDirCD := t.TempDir()
		gitCD := git.NewCmdConfig(t, git.WithDir(tmpDirCD))
		gitCDRun := func(args ...string) {
			_, err := gitCD.RunCmdE(args...)
			if err != nil {
				t.Fatal(err)
			}
		}

		gcloud.Runf(t, "source repos clone %s %s --project %s", cdRepo, tmpDirCD, mgmtProjectID)
		gitCDRun("config", "user.email", "secure-cicd-robot@example.com")
		gitCDRun("config", "user.name", "Secure CICD Robot")
		gitCDRun("config", "--global", "init.defaultBranch", "main")
		gitCDRun("checkout", "-b", "main")
		err := cp.Copy("../../../build/cloudbuild-cd.yaml", fmt.Sprintf("%s/cloudbuild-cd.yaml", tmpDirCD))
		fmt.Println(err)
		gitCDRun("add", ".")
		gitCD.CommitWithMsg("initial commit", []string{"--allow-empty"})
		gitCDRun("push", "-u", "origin", "main", "-f")

		// Push demo app source code, CI config, and policies
		tmpDirApp := t.TempDir()
		gitApp := git.NewCmdConfig(t, git.WithDir(tmpDirApp))
		gitAppRun := func(args ...string) {
			_, err := gitApp.RunCmdE(args...)
			if err != nil {
				t.Fatal(err)
			}
		}

		gitAppRun("clone", "--branch", "v0.5.11", "https://github.com/GoogleCloudPlatform/bank-of-anthos.git", tmpDirApp)
		gitAppRun("config", "user.email", "secure-cicd-robot@example.com")
		gitAppRun("config", "user.name", "Secure CICD Robot")
		gitAppRun("config", "--global", "credential.https://source.developers.google.com.helper", "gcloud.sh")
		gitAppRun("config", "--global", "init.defaultBranch", "main")
		gitAppRun("config", "--global", "http.postBuffer", "157286400")
		gitAppRun("checkout", "-b", "main")
		err2 := cp.Copy("../../../build/cloudbuild-ci.yaml", fmt.Sprintf("%s/cloudbuild-ci.yaml", tmpDirApp))
		fmt.Println(err2)
		err3 := cp.Copy("../../../examples/private_cluster_cicd/policies", fmt.Sprintf("%s/policies", tmpDirApp))
		fmt.Println(err3)
		gitAppRun("remote", "add", "google", appRepo)
		gitAppRun("add", ".")
		gitApp.CommitWithMsg("initial commit", []string{"--allow-empty"})
		gitAppRun("push", "--all", "google", "-f")

		lastCommit := gitApp.GetLatestCommit()
		// filter builds triggered based on pushed commit sha
		buildListCmd := fmt.Sprintf("builds list --region=%s --filter substitutions.COMMIT_SHA='%s' --project %s", region, lastCommit, mgmtProjectID)
		// poll build until complete
		pollCloudBuild := func(cmd string) func() (bool, error) {
			return func() (bool, error) {
				build := gcloud.Runf(t, cmd).Array()
				if len(build) < 1 {
					return true, nil
				}
				latestWorkflowRunStatus := build[0].Get("status").String()
				if latestWorkflowRunStatus == "SUCCESS" {
					return false, nil
				}
				return true, nil
			}
		}
		utils.Poll(t, pollCloudBuild(buildListCmd), 40, 30*time.Second)

		releaseName := fmt.Sprintf("release-%s", lastCommit[0:7])
		fmt.Println(releaseName)
		rolloutListCmd := fmt.Sprintf("deploy rollouts list --project=%s --delivery-pipeline=%s --region=%s --release=%s --filter targetId=%s", mgmtProjectID, pipelineName, region, releaseName, prodTarget)
		// Poll CD rollouts until prod rollout is successful
		pollCloudDeploy := func(cmd string) func() (bool, error) {
			return func() (bool, error) {
				rollouts := gcloud.Runf(t, cmd).Array()
				if len(rollouts) < 1 {
					return true, nil
				}
				latestRolloutState := rollouts[0].Get("state").String()
				if latestRolloutState == "SUCCEEDED" {
					return false, nil
				}
				return true, nil
			}
		}
		utils.Poll(t, pollCloudDeploy(rolloutListCmd), 30, 60*time.Second)
	})
	// call the test function to execute the integration test
	standaloneMultiProjT.Test()
}
