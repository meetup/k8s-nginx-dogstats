# Nginx Dogstats metrics via Fluentd for Kubernetes
[![Build Status](https://travis-ci.org/meetup/k8s-nginx-dogstats.svg?branch=master)](https://travis-ci.org/meetup/k8s-nginx-dogstats)
[![](https://images.microbadger.com/badges/version/meetup/k8s-nginx-dogstats.svg)](https://microbadger.com/images/meetup/k8s-nginx-dogstats "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/meetup/k8s-nginx-dogstats.svg)](https://microbadger.com/images/meetup/k8s-nginx-dogstats "Get your own image badge on microbadger.com")

Empower engineers with a default pipeline of
nginx metrics to Datadog from your cluster.

## About

We like k8s and we use nginx a lot, we'll likely
use it even more as a part of Cloud Endpoints.

So here we offer a default log parser that'll take
typical nginx stats and turn them into dogstats.

It matches the following nginx log format, which
should be included in a modified cloud endpoint
container when I publish it.

```
log_format timed_combined '$remote_addr - $remote_user [$time_local] '
    '"$request" $status $body_bytes_sent '
    '"$http_referer" "$http_user_agent" '
    '$request_time $upstream_response_time $pipe';
```

Upstream_response_time and pipe are not yet implemented.

### Metric tags

Each metric will be annotated with a set of tags including both kubernetes metadata
as well as request information.

### path_aliases

Many applications expose endpoints with paths containing dynamic portions. You
may find it useful to collapse these into an single alias to reduce their cardinality.

You can do so by volume mounting a yaml configuration file
```
$ docker run  -v $PWD/nginx_dogstats.yaml:/opt/nginx_dogstats.yaml  ...
```

This file expects a key named `path_aliases` which binds to a list of path
patterns and alias names. Below is an example

```yaml
path_aliases:
  - "^/cupcakes/.+$" : "/cupcakes/{id}"
```

Given the above a request with a path `/cupcakes/123` would yield a path tag of `/cupcakes/{id}`


## Testing

There's a component test on the artifact.
Simply, it spins up a mock-statsd server to record
what we attempt to send it then validates the results
against an existing expected output.

## Deployment

This project isn't meant to deploy, only publish, but
we have included some examples of how you could deploy it.
