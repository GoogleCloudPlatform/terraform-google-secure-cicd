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
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/shell"
)

// GetSecretFromSecretManager retrieves the latest version of a secret from Google Cloud Secret Manager using the gcloud CLI.
func GetSecretFromSecretManager(t *testing.T, secretName string, secretProject string) (string, error) {
	t.Log("Retrieving secret from secret manager.")
	cmd := fmt.Sprintf("secrets versions access latest --project=%s --secret=%s", secretProject, secretName)
	args := strings.Fields(cmd)
	gcloudCmd := shell.Command{
		Command: "gcloud",
		Args:    args,
		Logger:  logger.Discard,
	}
	return shell.RunCommandAndGetStdOutE(t, gcloudCmd)
}

func ReplacePatternInTfVars(pattern string, replacement string, root string) error {
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, fnErr error) error {
		if fnErr != nil {
			return fnErr
		}
		if !d.IsDir() && d.Name() == "terraform.tfvars" {
			return replaceInFile(path, pattern, replacement)
		}
		return nil
	})

	return err
}

func ReplacePatternInFile(pattern string, replacement string, root string, fileName string) error {
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, fnErr error) error {
		if fnErr != nil {
			return fnErr
		}
		if !d.IsDir() && d.Name() == fileName {
			return replaceInFile(path, pattern, replacement)
		}
		return nil
	})

	return err
}

func replaceInFile(filePath, oldPattern, newPattern string) error {
	fileInfo, err := os.Lstat(filePath)
	if err != nil {
		return err
	}

	if fileInfo.Mode()&os.ModeSymlink != 0 {
		fmt.Printf("%s is a symlink, will skip the pattern replacement.", filePath)
		return nil
	} else {
		content, err := os.ReadFile(filePath)
		if err != nil {
			return err
		}

		newContent := strings.ReplaceAll(string(content), oldPattern, newPattern)

		err = os.WriteFile(filePath, []byte(newContent), 0644)
		if err != nil {
			return err
		}

		fmt.Printf("Updated file: %s\n", filePath)

		return nil
	}
}
