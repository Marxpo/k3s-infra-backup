#!/bin/bash
# Installation du cluster hote : cert-manager + ClusterIssuer Let's Encrypt
# A executer depuis ~/ avec les wrappers scripts/kubectl.sh et scripts/helm.sh en place
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/helm.sh repo add jetstack https://charts.jetstack.io
./scripts/helm.sh repo update
./scripts/kubectl.sh create namespace cert-manager
./scripts/helm.sh install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true

echo "Attends que cert-manager soit Ready (kubectl get pods -n cert-manager) puis :"
echo "./scripts/kubectl.sh apply -f host-cluster/cert-manager/cluster-issuer.yaml"
