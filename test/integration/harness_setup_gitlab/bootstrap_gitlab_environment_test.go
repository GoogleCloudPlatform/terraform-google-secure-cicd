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

package harness_setup_gitlab

import (
	"fmt"
	"io"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/terraform-google-modules/terraform-google-secure-cicd/test/integration/testutils"
	gitlab "gitlab.com/gitlab-org/api/client-go"
)

// connects to a Google Cloud VM instance using SSH and retrieves the logs from the VM's Startup Script service
func readLogsFromVm(t *testing.T, instanceName string, instanceZone string, instanceProject string) (string, error) {
	args := []string{"compute", "ssh", instanceName, fmt.Sprintf("--zone=%s", instanceZone), fmt.Sprintf("--project=%s", instanceProject), "-q", "--command=journalctl -u google-startup-scripts.service -n 20"}
	gcloudCmd := shell.Command{
		Command: "gcloud",
		Args:    args,
	}
	return shell.RunCommandAndGetStdOutE(t, gcloudCmd)
}

func TestValidateStartupScript(t *testing.T) {
	// Retrieve output values from test setup
	setup := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../setup/harness/gitlab"),
	)
	instanceName := setup.GetStringOutput("gitlab_instance_name")
	instanceZone := setup.GetStringOutput("gitlab_instance_zone")
	gitlabProject := setup.GetStringOutput("gitlab_project_id")
	// Periodically read logs from startup script running on the VM instance
	for count := 0; count < 100; count++ {
		logs, err := readLogsFromVm(t, instanceName, instanceZone, gitlabProject)
		if err != nil {
			t.Fatal(err)
		}

		if strings.Contains(logs, "Finished Google Compute Engine Startup Scripts") {
			if strings.Contains(logs, "exit status 1") {
				t.Fatal("ERROR: Startup Script finished with invalid exit status.")
			}
			break
		}
		time.Sleep(12 * time.Second)
	}
}
func TestBootstrapGitlabVM(t *testing.T) {
	caCert, err := os.ReadFile("/usr/local/share/ca-certificates/gitlab.crt")

	if err != nil {
		t.Fatalf("Failed to read CA certificate: %v", err)
	}

	// Retrieve output values from test setup
	setup := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../setup/harness/gitlab"),
	)

	setupOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup"))

	servicePerimeterOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup/harness/service_perimeter"))

	clusterNetworkOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup/harness/cluster_network"))

	privateWorkerPoolOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup/harness/private_workerpool"))

	projectID := setupOutput.GetStringOutput("project_id_standalone")
	region := setupOutput.GetStringOutput("primary_location")

	gitlabSecretProject := setup.GetStringOutput("gitlab_secret_project")
	external_url := setup.GetStringOutput("gitlab_url")
	url := "https://gitlab.example.com"
	serviceDirectory := setup.GetStringOutput("gitlab_service_directory")
	gitlabSecretProjectNumber := setup.GetStringOutput("gitlab_secret_project_number")
	gitlabPersonalTokenSecretName := setup.GetStringOutput("gitlab_pat_secret_name")
	gitlabWebhookSecretId := setup.GetStringOutput("webhook_secret_id")
	gitlabTokenSecretId := fmt.Sprintf("projects/%s/secrets/%s", gitlabSecretProjectNumber, gitlabPersonalTokenSecretName)
	privateWorkerPoolId := privateWorkerPoolOutput.GetStringOutput("workerpool_id")
	clusterNetworkName := clusterNetworkOutput.GetStringOutput("network_name")

	accessLevelName := servicePerimeterOutput.GetStringOutput("access_level_name")

	token, err := testutils.GetSecretFromSecretManager(t, gitlabPersonalTokenSecretName, gitlabSecretProject)
	if err != nil {
		t.Fatal(err)
	}
	git, err := gitlab.NewClient(token, gitlab.WithBaseURL(external_url))
	if err != nil {
		t.Fatal(err)
	}
	repos := []string{
		"secure-ci",
		"secure-cd",
	}

	for _, repo := range repos {
		p := &gitlab.CreateProjectOptions{
			Name:                 gitlab.Ptr(repo),
			Description:          gitlab.Ptr("Test Repo"),
			InitializeWithReadme: gitlab.Ptr(true),
			Visibility:           gitlab.Ptr(gitlab.PrivateVisibility),
			DefaultBranch:        gitlab.Ptr("master"),
		}
		project, _, err := git.Projects.CreateProject(p)
		if err != nil {
			t.Error(err)
		} else {
			t.Log(project.WebURL)
			t.Log(project.Name)
		}

	}

	root := "../../.."

	err = testutils.ReplacePatternInTfVars("{PROJECT_ID}", projectID, root)
	if err != nil {
		t.Fatal(err)
	}

	err = testutils.ReplacePatternInTfVars("{ACCESS_LEVEL_NAME}", accessLevelName, root)
	if err != nil {
		t.Fatal(err)
	}

	err = testutils.ReplacePatternInTfVars("{REGION}", region, root)
	if err != nil {
		t.Fatal(err)
	}

	// Replace gitlab.com/user with custom self hosted URL using the root namespace

	replacement := fmt.Sprintf("%s/root", url)
	err = testutils.ReplacePatternInTfVars("https://gitlab.com/user", replacement, root)
	if err != nil {
		t.Fatal(err)
	}

	// Replace https://gitlab.com with custom self hosted URL
	err = testutils.ReplacePatternInTfVars("https://gitlab.com", url, root)
	if err != nil {
		t.Fatal(err)
	}

	// Replace SSL Cert
	err = testutils.ReplacePatternInTfVars("REPLACE_WITH_SSL_CERT\n", string(caCert), root)
	if err != nil {
		t.Fatal(err)
	}

	// Replace Service Directory
	err = testutils.ReplacePatternInTfVars("REPLACE_WITH_SERVICE_DIRECTORY", serviceDirectory, root)
	if err != nil {
		t.Fatal(err)
	}

	// Replace webhook secret id
	err = testutils.ReplacePatternInTfVars("REPLACE_WITH_WEBHOOK_SECRET_ID", gitlabWebhookSecretId, root)
	if err != nil {
		t.Fatal(err)
	}

	// Replace gitlab token secret ids
	err = testutils.ReplacePatternInTfVars("REPLACE_WITH_READ_API_SECRET_ID", gitlabTokenSecretId, root)
	if err != nil {
		t.Fatal(err)
	}

	// Replace secret project_id
	err = testutils.ReplacePatternInTfVars("REPLACE_WITH_SECRET_PROJECT_ID", gitlabSecretProject, root)
	if err != nil {
		t.Fatal(err)
	}

	err = testutils.ReplacePatternInTfVars("REPLACE_WITH_READ_USER_SECRET_ID", gitlabTokenSecretId, root)
	if err != nil {
		t.Fatal(err)
	}

	err = testutils.ReplacePatternInTfVars("{REPLACE_WITH_WORKER_POOL_ID}", privateWorkerPoolId, root)
	if err != nil {
		t.Fatal(err)
	}

	err = testutils.ReplacePatternInTfVars("{REPLACE_WITH_NETWORK_NAME}", clusterNetworkName, root)
	if err != nil {
		t.Fatal(err)
	}

	filePath := "../../../examples/standalone_single_project/terraform.tfvars"

	file, err := os.Open(filePath)
	if err != nil {
		t.Fatal(err)
	}

	b, err := io.ReadAll(file)
	if err != nil {
		t.Fatal(err)
	}

	t.Log(string(b))
}
