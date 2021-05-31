# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project_id = attribute('project_id')

repo_name_prefix                = "projects/#{project_id}/repos"
repo_name_accounts              = "accounts"
repo_name_bank_of_anthos_source = "bank-of-anthos-source"
repo_name_root_config_repo      = "root-config-repo"
repo_name_transactions          = "transactions"
repo_name_frontend              = "frontend"

bkt_name = "#{project_id}_cloudbuild"
bkt_folder_cache = "cache"
bkt_folder_dot_cache = ".cache"
bkt_folder_dot_m2 = ".m2"
bkt_folder_dot_skaffold = ".skaffold"

gar_region = "us-central1"
gar_name = "#{project_id}-boa-image-repo"

bin_authz_attestor_prefix = "projects/#{project_id}/attestors"
attestor_build = "build-attestor"
attestor_quality = "quality-attestor"
attestor_security = "security-attestor"

describe command("gcloud --project='#{project_id}' source repos list --format=json") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq '' }

  let!(:repos_data) do
    if subject.exit_status == 0
      JSON.parse(subject.stdout)
    else
      {}
    end
  end

  describe "repo: #{repo_name_accounts}" do
    it "exists" do
      expect(repos_data.select {|k,v| k['name'] == "#{repo_name_prefix}/#{repo_name_accounts}"}.size).to eq 1
    end
  end

  describe "repo: #{repo_name_bank_of_anthos_source}" do
    it "exists" do
      expect(repos_data.select {|k,v| k['name'] == "#{repo_name_prefix}/#{repo_name_bank_of_anthos_source}"}.size).to eq 1
    end
  end

  describe "repo: #{repo_name_root_config_repo}" do
    it "exists" do
      expect(repos_data.select {|k,v| k['name'] == "#{repo_name_prefix}/#{repo_name_root_config_repo}"}.size).to eq 1
    end
  end

  describe "repo: #{repo_name_transactions}" do
    it "exists" do
      expect(repos_data.select {|k,v| k['name'] == "#{repo_name_prefix}/#{repo_name_transactions}"}.size).to eq 1
    end
  end

  describe "repo: #{repo_name_frontend}" do
    it "exists" do
      expect(repos_data.select {|k,v| k['name'] == "#{repo_name_prefix}/#{repo_name_frontend}"}.size).to eq 1
    end
  end
end

describe command("gsutil ls -p #{project_id}") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match "gs://#{bkt_name}/" }
end

describe command("gsutil ls -p #{project_id} gs://#{bkt_name}/#{bkt_folder_cache}") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match "gs://#{bkt_name}/#{bkt_folder_cache}/#{bkt_folder_dot_cache}/\ngs://#{bkt_name}/#{bkt_folder_cache}/#{bkt_folder_dot_m2}/\ngs://#{bkt_name}/#{bkt_folder_cache}/#{bkt_folder_dot_skaffold}/" }
end

describe command("gcloud beta --project='#{project_id}' builds triggers describe #{attribute('build_trigger_name')} --format=json") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq '' }
end

describe command("gcloud --project='#{project_id}' artifacts repositories describe #{gar_name} --location #{gar_region} --format=json") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "Encryption: Google-managed key\n" }
end

describe command("gcloud beta --project='#{project_id}' container binauthz attestors list --format=json") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq '' }

  let!(:att_data) do
    if subject.exit_status == 0
      JSON.parse(subject.stdout)
    else
      {}
    end
  end

  describe "attestor: #{attestor_build}" do
    it "exists" do
      expect(att_data.select {|k,v| k['name'] == "#{bin_authz_attestor_prefix}/#{attestor_build}"}.size).to eq 1
    end
  end

  describe "attestor: #{attestor_quality}" do
    it "exists" do
      expect(att_data.select {|k,v| k['name'] == "#{bin_authz_attestor_prefix}/#{attestor_quality}"}.size).to eq 1
    end
  end

  describe "attestor: #{attestor_security}" do
    it "exists" do
      expect(att_data.select {|k,v| k['name'] == "#{bin_authz_attestor_prefix}/#{attestor_security}"}.size).to eq 1
    end
  end
end
