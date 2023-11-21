#!/bin/sh
# Create namespaces that are needed during bootstrapping
kubectl apply -f .bootstrap/ns.yaml

# Create empty TLS secrets that are necessary to fix a hen-and-egg problem with GCE-Ingress-Controller during certificate provisioning.
# The controller will only start the certificate process if the secret to write into already exist, but it would normally only be created by cert-manager during the process.
# These resources can't be managed by ArgoCD because it would overwrite the provisioned TLS certificate with the empty placeholder again.
kubectl apply -f ./bootstrap/empty-tls-secrets.yaml

# Secrets are created manually to ensure they are not leaked by using GitOps.
# In a production environment this issue might be addressed by using external-secrets or sealed-secrets.
kubectl create secret generic database -n vikunja \
  --from-literal=VIKUNJA_DATABASE_HOST=$VIKUNJA_DATABASE_HOST \
  --from-literal=VIKUNJA_DATABASE_USER=$VIKUNJA_DATABASE_USER \
  --from-literal=VIKUNJA_DATABASE_PASSWORD=$VIKUNJA_DATABASE_PASSWORD
kubectl create secret generic database -n keycloak \
  --from-literal=KEYCLOAK_DATABASE_HOST=$KEYCLOAK_DATABASE_HOST \
  --from-literal=KEYCLOAK_DATABASE_PORT=$KEYCLOAK_DATABASE_PORT \
  --from-literal=KEYCLOAK_DATABASE_DATABASE=$KEYCLOAK_DATABASE_DATABASE \
  --from-literal=KEYCLOAK_DATABASE_USER=$KEYCLOAK_DATABASE_USER \
  --from-literal=KEYCLOAK_DATABASE_PASSWORD=$KEYCLOAK_DATABASE_PASSWORD
kubectl create secret generic keycloak-admin -n keycloak \
  --from-literal=KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD

# Bootstrap ArgoCD
kubectl apply -k ./components/argocd/kustomize
kubectl apply -f ./apps/argocd-apps.yaml
