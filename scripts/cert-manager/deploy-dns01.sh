#!/usr/bin/env bash

# ==============================================================================
#
# Installs the Lets Encrypt dns01 Issuer with CloudFlare
#
# This can be used to get a single wildcard TLS certificate for the whole
# cluster and to be used by all services.
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

paramValidation "CLUSTER_FQN" \
    "the FQN for the cluster, like 'andromeda.nostran.com' "

paramValidation "CLOUDFLARE_EMAIL" \
    "the Cloudflare administrator account's email address"

paramValidation "CLOUDFLARE_API_KEY" \
    "the Cloudflare administrator account API key"

if [[ ${VAL_ONLY} ]]; then  return 0;  fi


# ==============================================================================
echoSection "Installing a CloudFlare / Let's Encrypt dns01 Issuer"
# ==============================================================================


echo "Namespace check AND definition in the shell"
defineNamespace cert-manager


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "cert-manager-dns01"


# ------------------------------------------------------------
echo "Adding K8s objects for the Cluster FQN: ${CLUSTER_FQN}"

export CLOUDFLARE_API_KEY_B64=$(echo -n "${CLOUDFLARE_API_KEY}" | base64 )

applyTemplate cloudflare-api-key-secret.yaml

applyTemplate cloudflare-issuer.yaml

applyTemplate cluster-certificate.yaml


# ------------------------------------------------------------
echo "Waiting for the certificate to be issued"

checkCertificateIssued cluster-fqn-certificate cert-manager

echo "Making the new TLS secret replicatable accross namespaces"

kubectl patch secret ${CLUSTER_CERT_SECRET_NAME} \
  --type json -p \
    '[{"op":"add","path":"/metadata/annotations/replicator.v1.mittwald.de~1replication-allowed", "value":"true"}]' \
    --namespace cert-manager

kubectl patch secret ${CLUSTER_CERT_SECRET_NAME} \
  --type json -p \
    '[{"op":"add","path":"/metadata/annotations/replicator.v1.mittwald.de~1replication-allowed-namespaces", "value": "'.*'"}]' \
    --namespace cert-manager

echoSection "Cert-manager's dns01 Issuer has been installed on your cluster'"
# ------------------------------------------------------------

