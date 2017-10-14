# Nginx Dogstats metrics via Fluentd for Kubernetes
[![Build Status](https://travis-ci.org/meetup/k8s-nginx-dogstats.svg?branch=master)](https://travis-ci.org/meetup/k8s-nginx-dogstats)
[![](https://images.microbadger.com/badges/version/meetup/k8s-nginx-dogstats.svg)](https://microbadger.com/images/meetup/k8s-nginx-dogstats "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/meetup/k8s-nginx-dogstats.svg)](https://microbadger.com/images/meetup/k8s-nginx-dogstats "Get your own image badge on microbadger.com")

Empower engineers with a default pipeline of
nginx metrics to Datadog from your cluster.

## About

We like [k8s](https://kubernetes.io/) and we use [nginx](https://www.nginx.com/) a lot, we'll likely
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

Below is a table of collected metrics and tags

#### Metrics

The majority of metrics below are collected from [nginx log module provided information](http://nginx.org/en/docs/http/ngx_http_log_module.html)

| Name | Description |
|------|-------------|
| nginx.request_time.{avg,count,max,median} | statistics about request processing time in seconds with a milliseconds resolution; time elapsed between the first bytes were read from the client and the log write after the last bytes were sent to the client |
| nginx.server_zone.responses.2xx | number of 2xx HTTP response code responses |
| nginx.server_zone.responses.3xx | number of 3xx HTTP response code responses |
| nginx.server_zone.response.4xx | number of 4xx HTTP response code responses |
| nginx.server_zone.response.5xx | number of 5xx HTTP response code responses |
| nginx.upstream_response_time.{avg,count,max,median, 95percentile} | statistics about time spent on receiving the response from the upstream server; the time is kept in seconds with millisecond resolution. |

#### Tags

Tags can be used to group metrics on order to drill down to the source of a metric

| Name | Description |
|-|-|
| status_code | precise HTTP response code |
| path | the HTTP request path. see [path_aliases](#path_aliases) notes below  |
| namespace | kubernetes provided namespace |
| kube_namespace | (same as above)  |
| container_name | kubernetes provided container name |
| pod_name | kubernetes provided container name  in `{namespace}/{pod-name}` format  |

### path_aliases

Many applications expose endpoints with paths containing dynamic segments representing resource identifiers. You
may find it useful to collapse these into an single alias to reduce metric `path` [tag](#Tags) cardinality.

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
