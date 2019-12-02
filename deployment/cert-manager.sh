#!/usr/bin/env bash

# ==============================================================================
#
# Installs Basic Cluster features that are typically needed in all clusters.
#
# - Helm's Tiller
#
# ==============================================================================

source shared.sh


# Stop immediately if any of the deployments fail
trap errorHandler ERR


# ------------------------------------------------------------
echoSection "Validating parameters"


if [[ ! ${LETS_ENCRYPT_ACME_EMAIL} ]]
then
    echo "ERROR: LETS_ENCRYPT_ACME_EMAIL env var is not defined."

    echo "Please define it with the email address you want to present to Let's Encript as the person responsible for the certs of your domain."

    exit 1
fi

# ------------------------------------------------------------
echoSection "Installing cert-manager for Let's Encrypt"

echo "Install the CustomResourceDefinition resources separately"
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml

echo "Create the namespace for cert-manager"
kubectl create namespace cert-manager

echo "Add the Jetstack Helm repository"
helm repo add jetstack https://charts.jetstack.io

echo "Update your local Helm chart repository cache"
helm repo update

echo "Install the cert-manager Helm chart"
helm install \
  --name cert-manager \
  --namespace cert-manager \
  --version v0.11.0 \
  jetstack/cert-manager


echoSection "cert-manager has been installed, testing the installation"

sleep 20s

echo "Create a ClusterIssuer to test the webhook works okay"

cat <<EOF > /tmp/test-resources.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: selfsigned-cert
  namespace: cert-manager-test
spec:
  commonName: example.com
  secretName: selfsigned-cert-tls
  issuerRef:
    name: test-selfsigned
EOF

echo "Create the test resources"
kubectl apply -f /tmp/test-resources.yaml

echo "Check the status of the newly created certificate"

# You may need to wait a few seconds before cert-manager processes the
# certificate request

sleep 5s

kubectl describe certificate -n cert-manager-test | grep "Certificate is up to date and has not expired"

echo "Clean up the test resources"

kubectl delete -f /tmp/test-resources.yaml

echo "Cert manager validation successful"

echoSection "Cert-manager has been installed and validated on your cluster"


# ------------------------------------------------------------
echo "Adding a default ClusterIssuer to the cluster (http01, Let's Encrypt)"

cat <<EOF | kubectl apply --namespace cert-manager -f -
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: "${LETS_ENCRYPT_ACME_EMAIL}"
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

echoSection "Cert-manager has been installed and validated on your cluster"
# ------------------------------------------------------------



# ------------------------------------------------------------
echoSection "SUCCESS: All Basic cluster features have been installed into your cluster."

