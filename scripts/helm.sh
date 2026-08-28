#!/bin/bash
docker run --rm -i --net=host \
  -v /home/claude/.kube/k3s-config:/root/.kube/config:ro \
  -v helm-data:/root/.cache/helm \
  -v helm-config:/root/.config/helm \
  alpine/helm:latest --kube-context=default "$@"
