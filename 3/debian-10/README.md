# Preparing a Custom Moodle Image

## Building

build-latest.sh will build image ss-moodle and push it to ECS.

## Logging

You can enable logging of standard debug messages by setting the environment variable BITNAMI_DEBUG=true.

You can enable logging of Aurora error messages by setting appropriate variables in "moodle-cluster-parameters".

You can insert custom debug messages into the flow by adding "info" statements:

```
info "yada yada yad"
```
