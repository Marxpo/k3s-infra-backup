#!/bin/bash
# Installation de Vault dans le vcluster (namespaces vault + oci-tools)
set -euo pipefail
cd "$(dirname "$0")/../.."

./scripts/vcluster-kubectl.sh create namespace vault
./scripts/vcluster-kubectl.sh create namespace oci-tools

./scripts/vcluster-helm.sh repo add hashicorp https://helm.releases.hashicorp.com
./scripts/vcluster-helm.sh repo update

./scripts/vcluster-helm.sh install vault hashicorp/vault \
  --namespace vault \
  --set "server.dataStorage.enabled=true" \
  --set "server.dataStorage.size=2Gi" \
  --set "injector.enabled=true" \
  --set "global.tlsDisable=true"

echo ""
echo "Vault est deploye mais SCELLE. A faire toi-meme (jamais via un assistant) :"
echo ""
echo "  sudo k3s kubectl --context default -n loft-default-v-tools \\"
echo "    exec vault-0-x-vault-x-tools -- vault operator init -key-shares=1 -key-threshold=1"
echo "  # -> conserve la cle de descellement + le root token en lieu sur"
echo ""
echo "  sudo k3s kubectl --context default -n loft-default-v-tools \\"
echo "    exec vault-0-x-vault-x-tools -- vault operator unseal <CLE_DE_DESCELLEMENT>"
echo ""
echo "Puis lance configure.sh (dans un shell exec sur vault-0, avec 'vault login' fait a la main)."
