#!/bin/bash
# Installation d'ArgoCD dans le vcluster, namespace "argocd"
set -euo pipefail
cd "$(dirname "$0")/../.."

./scripts/vcluster-kubectl.sh create namespace argocd

curl -fsSL -o /tmp/argocd-install.yaml https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# IMPORTANT: --server-side, pas "apply" classique.
# Le CRD applicationsets.argoproj.io depasse la limite de 256Ko pour l'annotation
# last-applied-configuration qu'un "kubectl apply" normal essaie de stocker.
cat /tmp/argocd-install.yaml | docker run --rm -i --net=host \
  -v /home/claude/.kube/vcluster-tools-config:/tmp/vc-config:ro \
  bitnami/kubectl:latest --kubeconfig=/tmp/vc-config -n argocd apply --server-side --force-conflicts -f -

echo "Attends que les 7 pods soient Running (kubectl get pods -n argocd), puis :"
echo ""
echo "# Mode insecure (Traefik gere deja le TLS, evite le double chiffrement) :"
echo "./scripts/vcluster-kubectl.sh -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{\"data\":{\"server.insecure\":\"true\"}}'"
echo "./scripts/vcluster-kubectl.sh -n argocd rollout restart deployment argocd-server"
echo ""
echo "# Ingress HTTPS publique :"
echo "./scripts/vcluster-kubectl.sh apply -f vcluster-tools/argocd/ingress.yaml"
echo ""
echo "# Mot de passe admin initial (genere par ArgoCD, a changer immediatement) :"
echo "./scripts/vcluster-kubectl.sh get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
