#!/bin/bash
# Copyright 2021 Google LLC
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

#!/bin/sh

GCLOUD_LOCATION=$(command -v gcloud)
echo "Using gcloud from $GCLOUD_LOCATION"

gcloud --version
echo "running gcloud builds submit $1 --project $2 --config=$1/$3 --substitutions=_DEFAULT_REGION=$4,_GAR_REPOSITORY=$5 --gcs-source-staging-dir=$6"

gcloud builds submit "$1" --project "$2" --config="$1"/"$3" --substitutions=_DEFAULT_REGION="$4",_GAR_REPOSITORY="$5" --gcs-source-staging-dir="$6"
