/**
 * Copyright 2026 Google LLC
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
check "gcs_bucket_name_length" {
  assert {
    condition     = length(local.cache_bucket_name) < 63
    error_message = "The following constructed log bucket names are too long (max 63 characters): ${local.cache_bucket_name}. Please shorten the corresponding 'repository_name' in your variables or the 'project_id'."
  }
}
