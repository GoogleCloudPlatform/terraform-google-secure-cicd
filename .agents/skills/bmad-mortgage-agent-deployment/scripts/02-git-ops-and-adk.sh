#!/bin/bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e

# This script handles the initial population of the CI repository for a specific service.
# It uses a Personal Access Token retrieved from Secret Manager to authenticate with GitHub.

# Usage example:
# export CI_REPO_URL="https://github.com/your-org/your-ci-repo.git"
# export GITHUB_PAT_SECRET="your-github-pat-secret-name"
# ./02-git-ops-and-adk.sh <service_name> <git_email> <git_name>

SERVICE_NAME=$1
GIT_USER_EMAIL=$2
GIT_USER_NAME=$3

if [ -z "$SERVICE_NAME" ] || [ -z "$GIT_USER_EMAIL" ] || [ -z "$GIT_USER_NAME" ]; then
  echo "Error: You must provide SERVICE_NAME, GIT_USER_EMAIL, and GIT_USER_NAME as arguments."
  exit 1
fi

if [ -z "$CI_REPO_URL" ] || [ -z "$GITHUB_PAT_SECRET" ]; then
  echo "Error: The environment variables CI_REPO_URL and GITHUB_PAT_SECRET are required."
  exit 1
fi

# Fetch the Personal Access Token for GitHub from Secret Manager
GITHUB_PAT=$(gcloud secrets versions access latest --secret="$GITHUB_PAT_SECRET")

# Build the authenticated URL (GitHub requires x-access-token as the username)
AUTH_CI_REPO_URL="https://x-access-token:$GITHUB_PAT@${CI_REPO_URL#https://}"

# Populates a remote repository with the contents of a prepared directory.
# If the remote repository already contains commits, it clones the repo and adds a new commit.
# If it is empty, it initializes a fresh repository and pushes the initial commit.
# Required parameters: <content_dir> <authenticated_url> <commit_message>
seed_repo() (
  CONTENT_DIR=$1
  REPO_URL=$2
  COMMIT_MSG=$3

  if git ls-remote --heads "$REPO_URL" 2>/dev/null | grep -q .; then
    echo "The remote repository already has commits. Proceeding to clone and update."
    WORK_DIR=$(mktemp -d)
    git clone "$REPO_URL" "$WORK_DIR"
    cp -r "$CONTENT_DIR"/. "$WORK_DIR"/
    cd "$WORK_DIR"
    git config user.email "$GIT_USER_EMAIL"
    git config user.name "$GIT_USER_NAME"
    git add -A
    if git diff --cached --quiet; then
      echo "No modifications detected. The repository is already up to date."
    else
      git commit -m "$COMMIT_MSG"
      git push origin HEAD
    fi
    rm -rf "$WORK_DIR"
  else
    echo "The remote repository is empty. Initializing a fresh repository."
    cd "$CONTENT_DIR"
    git init
    git config user.email "$GIT_USER_EMAIL"
    git config user.name "$GIT_USER_NAME"
    git checkout -b main
    git add .
    git commit -m "$COMMIT_MSG"
    git remote add origin "$REPO_URL"
    git push -u origin main
  fi
)

# --- Populating CI Repository ---
echo "--- Starting CI Repository seeding for $SERVICE_NAME ---"
CI_TEMP_DIR=$(mktemp -d)
echo "CI temporary directory in use: $CI_TEMP_DIR"

cp -r "examples/mortgage-agent/src/$SERVICE_NAME/"* "$CI_TEMP_DIR/"
cp "examples/mortgage-agent/cloud_run/$SERVICE_NAME.yaml" "$CI_TEMP_DIR/"
cp "build/cloudbuild-ci.yaml" "$CI_TEMP_DIR/"
cp -r "build/policies" "$CI_TEMP_DIR/"

# We only need the rendered skaffold.yaml for the pipeline; removing the template file.
rm -f "$CI_TEMP_DIR/skaffold.yaml.tmpl"

seed_repo "$CI_TEMP_DIR" "$AUTH_CI_REPO_URL" "Initial commit for $SERVICE_NAME CI"
rm -rf "$CI_TEMP_DIR"
echo "The CI Repository for $SERVICE_NAME was seeded successfully."

echo "Finished processing $SERVICE_NAME."
