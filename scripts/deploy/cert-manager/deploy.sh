#!/usr/bin/env bash

# ==============================================================================
#
# Installs Cert-Manager for getting TLS certificates easily for ingresses.
#
# Defines Let's Encrypt as a ClusterIssuer for easy certificate requests.
#
# It also creates a wildcard TLS certificate if the CLUSTER_FQN variable
# is defined (With Let's Encrypt).
#
# Requires Helm.
#
# ==============================================================================

CERT_MAN_REL_VERSION=0.11
CERT_MAN_CHART_VERSION=0.11.0


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying Cert-Manager and Let's Encrypt to your cluster"

# ------------------------------------------------------------
echoSection "Validating parameters for Cert-Manager"

paramValidation "LETS_ENCRYPT_ACME_EMAIL" \
   "the email address you want to present to Let's Encript as the person responsible for the certs of your domain."

if [[ "${LETS_ENCRYPT_DEPLOY_PS_CERTS}" == "Y" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/deploy-http01.sh "VALIDATE_ONLY"
fi

if [[ "${LETS_ENCRYPT_DEPLOY_WC_CERT}" == "Y" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/deploy-http01.sh "VALIDATE_ONLY"
fi


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "cert-manager"


# ------------------------------------------------------------
echoSection "Installing cert-manager with Helm"

echo "Install the CustomResourceDefinitions separately"
kubectl apply --validate=false \
  -f https://raw.githubusercontent.com/jetstack/cert-manager/release-${CERT_MAN_REL_VERSION}/deploy/manifests/00-crds.yaml

echo "Create the namespace for cert-manager"
defineNamespace cert-manager

echo "Add the Jetstack Helm repository"
helm repo add jetstack https://charts.jetstack.io

echo "Install the cert-manager Helm chart"
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v${CERT_MAN_CHART_VERSION}


echoSection "Cert-Manager artifacts have been installed on the cluster"

# ------------------------------------------------------------
echo "Verifying the installation"

echo "Waiting for the Cert-Manager installation to stabilize"
waitAllPodsActive cert-manager 600 5

# There are no readiness probes on cert-manager deployments so we need to wait
# further
sleep 60

echo "Create a ClusterIssuer to test the webhook works okay"

echo "Create the test resources"
kubectl apply -f test-resources.yaml

echo "Check the status of the newly created certificate"

# You may need to wait a few seconds before cert-manager processes the
# certificate request

sleep 20s

kubectl describe certificate -n cert-manager-test \
   | grep "Certificate is up to date and has not expired"

echo "Clean up the test resources"

kubectl delete -f test-resources.yaml

echo "Cert manager validation successful"

echoSection "Cert-manager has been installed and validated on your cluster"
# ------------------------------------------------------------


if [[ "${LETS_ENCRYPT_DEPLOY_PS_CERTS}" == "Y" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/deploy-http01.sh
fi

if [[ "${LETS_ENCRYPT_DEPLOY_WC_CERT}" == "Y" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/deploy-dns01.sh
fi


# ------------------------------------------------------------
echoSection "SUCCESS: All required Cert-Manager features have been installed into your cluster."

