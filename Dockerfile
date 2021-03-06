# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:16.04

# Disable prompts from apt.
ENV DEBIAN_FRONTEND noninteractive
# Keeps unneeded configs from being installed along with fluentd.
ENV DO_NOT_INSTALL_CATCH_ALL_CONFIG true

RUN apt-get -q update && \
    apt-get install -y curl build-essential ruby && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    curl -s https://dl.google.com/cloudagents/install-logging-agent.sh | bash

# Install the record reformer and systemd plugins.
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-record-reformer -v 0.8.1
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-systemd -v 0.0.3
RUN /usr/sbin/google-fluentd-gem install statsd-ruby -v 1.3.0
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-statsd-output -v 1.1.1
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-grep -v 0.3.4
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-gcloud-pubsub-custom -v 0.4.2
RUN /usr/sbin/google-fluentd-gem install activesupport -v 4.2.6
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-kubernetes_metadata_filter -v 0.26.3
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-parser -v 0.6.1
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-json-transform -v 0.0.2
RUN /usr/sbin/google-fluentd-gem install fluent-plugin-dogstatsd -v 0.0.6

# Remove the misleading log file that gets generated when the agent is installed
RUN rm -rf /var/log/google-fluentd

ADD google-fluentd.conf /etc/google-fluentd/google-fluentd.conf
ADD datadog-transformer.rb /opt/datadog-transformer.rb

# Start Fluentd to pick up our config that watches Docker container logs.
ENTRYPOINT ["/usr/sbin/google-fluentd"]
