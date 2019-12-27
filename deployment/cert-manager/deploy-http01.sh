#!/usr/bin/env bash

# ==============================================================================
#
# Installs the Lets Encrypt http01 ClusterIssuer
#
# This can be used to get TLS certificates for each service
#
# Arguments:
# 1 - operating mode. VALIDATE_ONLY or FULL.
#     If VALIDATE, it stops after validating the parameters
# ==============================================================================

operatingMode=$1

source ../shared.sh


# Stop immediately if any of the deployments fail
trap errorHandler ERR


echoSection "Installing a default Let's Encrypt http01 ClusterIssuer"

defineNamespace "cert-manager"

# ------------------------------------------------------------
echoSection "Validating parameters"

paramValidation "LETS_ENCRYPT_ACME_EMAIL" \
   "the email address you want to present to Let's Encript as the person responsible for the certs of your domain."

if [[ "VALIDATE_ONLY" == "${operatingMode}" ]]
then
    exit 0
fi

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "cert-manager-http01"


# ------------------------------------------------------------
echo "Adding a default http01 ClusterIssuer to the cluster (Let's Encrypt)"

applyTemplate cluster-issuer.yaml

echoSection "Cert-manager's http01 Issuer has been installed on your cluster'"


