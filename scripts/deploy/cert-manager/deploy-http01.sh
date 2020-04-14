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


# Stop immediately if any of the deployments fail
trap errorHandler ERR


if [[ "VALIDATE_ONLY" = "${operatingMode}" ]]
then
    VAL_ONLY=Y
else
    unset VAL_ONLY
fi

# ------------------------------------------------------------
if [[ ! ${VAL_ONLY} ]]; then  echoSection "Validating parameters";  fi

paramValidation "LETS_ENCRYPT_ACME_EMAIL" \
   "the email address you want to present to Let's Encript as the person responsible for the certs of your domain."

if [[ ${VAL_ONLY} ]]; then  return 0;  fi


echoSection "Installing a default Let's Encrypt http01 ClusterIssuer"

echo "Namespace check AND definition in the shell"
defineNamespace cert-manager

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "cert-manager-http01"


# ------------------------------------------------------------
echo "Adding a default http01 ClusterIssuer to the cluster (Let's Encrypt)"

applyTemplate cluster-issuer.yaml

echoSection "Cert-manager's http01 Issuer has been installed on your cluster'"


