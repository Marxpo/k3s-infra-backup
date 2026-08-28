#!/bin/sh
# A executer A L'INTERIEUR du pod vault-0 (kubectl exec -it vault-0-x-vault-x-tools -- sh)
# apres avoir fait "vault login" avec le root token.
set -eu

vault auth enable kubernetes
vault write auth/kubernetes/config kubernetes_host="https://${KUBERNETES_SERVICE_HOST}:443"

vault secrets enable -path=secret kv-v2

vault policy write oci-tools-policy - <<EOF
path "secret/data/oci-tools/oci/credentials" {
  capabilities = ["read"]
}
EOF

vault write auth/kubernetes/role/oci-tools-role \
    bound_service_account_names=oci-retry \
    bound_service_account_namespaces=oci-tools \
    policies=oci-tools-policy \
    ttl=1h

echo "Config Vault terminee. Reste a stocker le secret OCI toi-meme :"
echo '  vault kv put secret/oci-tools/oci/credentials config="..." oci_api_key.pem="$(cat /tmp/oci_api_key.pem)"'
