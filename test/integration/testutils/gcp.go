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

package testutils

import (
	"fmt"

	"github.com/mitchellh/go-testing-interface"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
)

// GetOrgACMPolicyID gets the Organization Access Context Manager Policy ID
func GetOrgACMPolicyID(t testing.TB, orgID string) string {
	filter := fmt.Sprintf("parent:organizations/%s", orgID)
	t.Log("Getting Access Policy id.")
	id := gcloud.Runf(t, "access-context-manager policies list --organization %s --filter %s --quiet", orgID, filter).Array()
	if len(id) == 0 {
		t.Log("Access Policy does not exists.")
		return ""
	}
	acmD := GetLastSplitElement(id[0].Get("name").String(), "/")
	t.Logf("Access Policy successfuly retrieved %s.", acmD)
	return acmD
}

// CreateOrgACMPolicyID gets the Organization Access Context Manager Policy ID
func CreateOrgACMPolicyID(t testing.TB, orgID string) (string, error) {
	t.Log("Creating Access Policy id.")
	return gcloud.RunCmdE(t, fmt.Sprintf("access-context-manager policies create --organization %s --title '%s' --quiet", orgID, "Organization access level policy"))
}

// DeleteOrgACMPolicyID deletes the Organization Access Context Manager Policy ID
func DeleteOrgACMPolicyID(t testing.TB, acmD string) (string, error) {
	t.Log("Deleting Access Policy id.")
	return gcloud.RunCmdE(t, fmt.Sprintf("access-context-manager policies delete %s --quiet", acmD))
}

func CleanOrgACMPolicyID(t testing.TB, orgID string) {
	t.Log("Cleaning Access Policy id.")
	filter := fmt.Sprintf("parent:organizations/%s AND scopes:folders/*", orgID)
	t.Log("Getting Access Policy id.")
	acmDs := gcloud.Runf(t, "access-context-manager policies list --organization %s --filter \"%s\" --quiet", orgID, filter).Array()
	t.Log(acmDs)
	for _, acmD := range acmDs {
		t.Log("Deleting Access Policy id %s", acmD.Get("name"))
		_, err := gcloud.RunCmdE(t, fmt.Sprintf("access-context-manager policies delete %s --quiet", acmD.Get("name")))
		if err != nil {
			t.Log(err)
		}
	}
}
