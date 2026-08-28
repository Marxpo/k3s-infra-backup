#!/bin/bash
docker run --rm -i --net=host -v /home/claude/.kube/k3s-config:/tmp/k3s-config:ro bitnami/kubectl:latest --kubeconfig=/tmp/k3s-config --context=default "$@"
