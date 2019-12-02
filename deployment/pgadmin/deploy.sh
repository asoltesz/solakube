#!/usr/bin/env bash

# ==============================================================================
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of pgAdmin
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-prod"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION=1.0.4

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR


# ------------------------------------------------------------
echoSection "Validating parameters"

paramValidation "PGADMIN_FQN" \
   "the Fully Qualified Domain Name, you want to access pgAdmin with from outside the cluster. e.g.: pgadmin.example.com"

if [[ ! "${PGADMIN_STORAGE_CLASS}" ]]
then
    echo "Storage class was not defined: using 'default' "
    PGADMIN_STORAGE_CLASS="default"
else
    echo "Using storage class: '"${PGADMIN_STORAGE_CLASS}"' "
fi

if [[ ! "${PGADMIN_APP_NAME}" ]]
then
    echo "Application name not defined: using 'pgadmin' "
    PGADMIN_APP_NAME="pgadmin"
else
    echo "Using application name: '"${PGADMIN_APP_NAME}"' "
fi


# ------------------------------------------------------------
echoSection "Preparing temp folder"

TMP_DIR=/tmp/helm/pgadmin
rm -Rf ${TMP_DIR}
mkdir -p ${TMP_DIR}

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

envsubst < chart-values.yaml > ${TMP_DIR}/chart-values.yaml

envsubst < certificate.yaml > ${TMP_DIR}/certificate.yaml

envsubst < ingress.yaml > ${TMP_DIR}/ingress.yaml

envsubst < pvc.yaml > ${TMP_DIR}/pvc.yaml


# ------------------------------------------------------------
echoSection "Creating namespace"

addNamespace ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

kubectl apply -f ${TMP_DIR}/pvc.yaml \
        --namespace ${PGADMIN_APP_NAME}


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install stable/pgadmin \
    --name ${PGADMIN_APP_NAME} \
    --namespace ${PGADMIN_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------
echoSection "Installing the TLS certificate request"

kubectl apply -f ${TMP_DIR}/certificate.yaml \
        --namespace ${PGADMIN_APP_NAME}


# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

kubectl apply -f ${TMP_DIR}/ingress.yaml \
        --namespace ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "PgAdmin has been installed on your cluster"

