#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

publish_tag=$1

docker run -d \
  --name statsd-mock \
  -v $DIR/statsd-mock/index.js:/opt/index.js \
  node:7.7.1-alpine node /opt/index.js

docker run -d \
  --name gce-meta-mock \
  -v $DIR/gce-meta-mock/index.js:/opt/index.js \
  node:7.7.1-alpine node /opt/index.js

docker run -d \
  --name fluentd \
  --link statsd-mock:dogstatsd.datadog \
  --link gce-meta-mock:metadata.google.internal \
  -v $DIR/containers:/var/log/containers \
  -v $DIR/nginx_dogstats.yaml:/opt/nginx_dogstats.yaml \
  $publish_tag

# Give fluentd a second to process.
sleep 5

# Stop fluentd (flushing any statd buffer)
docker stop fluentd
docker rm fluentd

# Print logs from gce-meta-mock and delete container
docker rm -f gce-meta-mock

# Grab logs from statd-mock and sort them.
mkdir -p $DIR/target
docker logs statsd-mock | sort > $DIR/target/statsd-mock.log
docker rm -f statsd-mock

# Sort our expected output to match.
sort $DIR/expected/statsd-mock.log > $DIR/target/statsd-mock-expected.log

diff $DIR/target/statsd-mock-expected.log $DIR/target/statsd-mock.log
