# Backup infra k3s + Loft + Vault + ArgoCD + n8n

Sauvegarde de toute la configuration mise en place sur la VM (k3s hote, vcluster
`tools` via Loft, Vault, n8n, ArgoCD, pod de creation automatique de VM OCI).
But : pouvoir tout reconstruire sans repartir de zero apres une reinstallation
de la VM.

Un document PDF plus complet (schema d'architecture, explications, pieges
rencontres) a ete produit en parallele de ce repo pendant la session -- ce
repo est la partie "executable" (scripts + manifests), le PDF est la partie
narrative/pedagogique.

## Ordre de reconstruction

1. **Docker + k3s** installes sur la VM (remplace minikube).
2. **Corriger le reseau Docker si besoin** -- si des containers Docker classiques
   n'ont plus de sortie Internet (DNS/IP en timeout) apres l'install de k3s,
   c'est que kube-router/flannel a evince la regle MASQUERADE de docker0 :
   ```
   docker run --rm --privileged --net=host nicolaka/netshoot \
     iptables -t nat -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
   ```
3. Copier `scripts/` sur la nouvelle VM, `chmod +x scripts/*.sh`.
4. Recuperer le kubeconfig k3s :
   ```
   docker run --rm -v /etc/rancher/k3s:/k3s:ro alpine cat /k3s/k3s.yaml > ~/.kube/k3s-config
   chmod 644 ~/.kube/k3s-config
   ```
5. `host-cluster/install.sh` -- cert-manager + ClusterIssuer Let's Encrypt.
6. Installer la plateforme **Loft** (UI de gestion de vclusters) si tu veux
   repasser par elle -- sinon un vcluster peut etre cree directement en Helm
   (voir le PDF, section 3.4).
7. **Creer le vcluster `tools` via l'UI Loft** (recommande -- Loft garde un
   suivi interne qui se desynchronise si le vcluster est cree en CLI puis
   supprime en CLI).
8. Recuperer son kubeconfig et l'IP du Service, adapter `scripts/vcluster-*.sh` :
   ```
   docker run --rm --net=host -v ~/.kube/k3s-config:/tmp/k3s-config:ro bitnami/kubectl:latest \
     --kubeconfig=/tmp/k3s-config --context=default -n loft-default-v-tools \
     get secret vc-tools -o jsonpath='{.data.config}' | base64 -d > ~/.kube/vcluster-tools-config
   sed -i 's|server: https://localhost:8443|server: https://<CLUSTER-IP-DU-SVC-tools>:443|' \
     ~/.kube/vcluster-tools-config
   ```
9. `vcluster-tools/vault/install.sh` puis init/unseal (a la main) puis
   `configure.sh` (a la main, avec le root token) puis restocker le secret OCI.
10. `vcluster-tools/oci-tools/` -- appliquer `oci-retry-serviceaccount.yaml`
    puis `oci-retry-pod.yaml` (adapter les OCID a ton tenancy).
11. `vcluster-tools/n8n/n8n.yaml` -- `kubectl apply -f`.
12. `vcluster-tools/argocd/install.sh` puis `ingress.yaml`.
13. `vcluster-tools/demo-app/application.yaml` -- pointe vers le repo
    [demo-gitops-app](https://github.com/Marxpo/demo-gitops-app), separe de celui-ci.

## Contenu

```
host-cluster/
  install.sh                      cert-manager
  cert-manager/cluster-issuer.yaml Let's Encrypt (HTTP-01 via Traefik)
scripts/
  kubectl.sh, helm.sh              wrappers Docker vers le cluster hote
  vcluster-kubectl.sh, vcluster-helm.sh   wrappers vers le vcluster tools
  oci-cli.sh                       wrapper OCI CLI (image officielle Oracle)
vcluster-tools/
  vault/          install.sh + configure.sh
  oci-tools/      ServiceAccount + Pod (retry creation VM OCI, secrets via Vault Injector)
  n8n/            Deployment + Service + PVC
  argocd/         install.sh + ingress.yaml
  demo-app/       Application ArgoCD (pointe vers un repo Git separe)
```

## Ce qui n'est PAS dans ce repo (volontairement)

- Cle privee API OCI, mot de passe admin des bases, tokens GitHub/Vault --
  rien de tout ca n'a jamais ete stocke en fichier, tout vit uniquement dans
  Vault ou a ete communique une seule fois en direct.
- Le manifeste complet `argocd-install.yaml` (1.9 Mo) n'est pas versionne ici --
  `install.sh` le retelecharge depuis la branche `stable` officielle a chaque
  fois, pour toujours avoir la derniere version stable et eviter de vendorer
  un fichier aussi volumineux.
