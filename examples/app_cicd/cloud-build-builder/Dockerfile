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

# Start by building the application.
FROM golang:1.15-buster as kritis-build

# Install kritis
WORKDIR /go/src
RUN git clone https://github.com/grafeas/kritis
RUN mv kritis app
RUN go get -d -v ./...
WORKDIR /go/src/app
RUN make out/signer
RUN cp out/signer /signer

FROM alpine:3.18

### 1. Get Java via the package manager
RUN apk update \
&& apk upgrade \
&& apk add --no-cache bash curl jq openjdk17-jre git openssh \
&& apk add --no-cache --virtual=build-dependencies unzip

### Set JAVA_HOME
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk"

### 2. Get Python, PIP
RUN apk add --no-cache python3 \
&& python3 -m ensurepip \
&& pip3 install --upgrade pip setuptools \
&& rm -r /usr/lib/python*/ensurepip && \
if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
rm -r /root/.cache

#### 3. Install gcloud
ENV CLOUD_SDK_VERSION="423.0.0"
ENV CLOUDSDK_INSTALL_DIR /usr/local/gcloud/
RUN wget "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz" \
&& tar -C /usr/local -xzf "google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz" \
&& rm "google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"
ENV PATH $PATH:/usr/local/google-cloud-sdk/bin

#### Install skaffold and other components via gcloud
RUN gcloud components install skaffold kubectl kustomize kpt nomos beta

##### 4. Add the kritis signer to the commands
COPY --from=kritis-build /signer .

#### 4. Install YQ for parsing
RUN curl -Lo yq https://github.com/mikefarah/yq/releases/download/v4.6.1/yq_linux_amd64
RUN chmod +x yq
RUN mv ./yq /usr/local/bin

# Print out java version
RUN echo -e "JAVA_VERSION: $(${JAVA_HOME}/bin/java --version)"
RUN echo -e "PYTHON: $(python --version)\nPIP: $(pip --version)"

RUN gcloud --version

CMD ["/bin/bash"]
