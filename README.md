# Nginx Dogstats metrics via Fluentd for Kubernetes

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

## Testing

There's a component test on the artifact.
Simply, it spins up a mock-statsd server to record
what we attempt to send it then validates the results
against an existing expected output.

## Deployment

This project isn't meant to deploy, only publish, but
we have included some examples of how you could deploy it.
