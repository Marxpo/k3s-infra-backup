#!/bin/bash
docker run --rm -i --net=host \
  -v /home/claude/.kube/vcluster-tools-config:/tmp/vc-config:ro \
  bitnami/kubectl:latest --kubeconfig=/tmp/vc-config "$@"
