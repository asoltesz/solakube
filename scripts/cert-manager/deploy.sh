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
# 1 - The operation to execute
#     - install - new Cert Manager installation (deploys backup, test install ...etc)
#     - upgrade - only upgrade CM with Helm
# ==============================================================================

OPERATION=${1:-"install"}

CERT_MAN_REL_VERSION=0.11
CERT_MAN_CHART_VERSION=0.11.0


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying Cert-Manager and Let's Encrypt to your cluster"

# ------------------------------------------------------------
echoSection "Validating parameters for Cert-Manager"

if [[ -z $(echo ",install,upgrade," | grep ",${OPERATION},") ]]
then
    echo "FATAL: Unsupported script operation mode: ${OPERATION}"
    exit 1
fi

paramValidation "LETS_ENCRYPT_ACME_EMAIL" \
   "the email address you want to present to Let's Encript as the person responsible for the certs of your domain."

if [[ ${OPERATION} == "install" ]]
then
    if [[ "${LETS_ENCRYPT_DEPLOY_PS_CERTS}" == "Y" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/deploy-http01.sh "VALIDATE_ONLY"
    fi

    if [[ "${LETS_ENCRYPT_DEPLOY_WC_CERT}" == "Y" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/deploy-http01.sh "VALIDATE_ONLY"
    fi
fi

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "cert-manager"


# ------------------------------------------------------------
echoSection "Installing cert-manager with Helm"

echo "Install the CustomResourceDefinitions separately"

GITHUB_REPO="https://raw.githubusercontent.com/jetstack/cert-manager"

kubectl apply --validate=false \
  -f ${GITHUB_REPO}/release-${CERT_MAN_REL_VERSION}/deploy/manifests/00-crds.yaml

echo "Create the namespace for cert-manager"
defineNamespace cert-manager

processTemplate chart-values.yaml

echo "Add the Jetstack Helm repository"
helm repo add jetstack https://charts.jetstack.io

echo "Install the cert-manager Helm chart"
helm upgrade cert-manager jetstack/cert-manager \
  --install \
  --namespace cert-manager \
  --version v${CERT_MAN_CHART_VERSION} \
  --values ${TMP_DIR}/chart-values.yaml


echoSection "Cert-Manager artifacts have been installed on the cluster"

# ------------------------------------------------------------
if [[ ${OPERATION} == "install" ]]
then

    echoSection "Verifying the installation with a test ClusterIssuer"

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

    echo "ClusterIssuer test has been successful"

    # ------------------------------------------------------------
    echoSection "Deploying http01 and dns01 issuers"

    if [[ "${LETS_ENCRYPT_DEPLOY_PS_CERTS}" == "Y" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/deploy-http01.sh
    fi

    if [[ "${LETS_ENCRYPT_DEPLOY_WC_CERT}" == "Y" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/deploy-dns01.sh
    fi

    # ------------------------------------------------------------
    echoSection "Deploying Velero backup schedule"

    DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile "cert-manager")"

    if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
    else
        echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
    fi
fi

# ------------------------------------------------------------
echoSection "SUCCESS: All required Cert-Manager features have been installed into your cluster."

