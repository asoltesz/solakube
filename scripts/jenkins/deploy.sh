#!/usr/bin/env bash

# ==============================================================================
#
# Install Jenkins CI/CD on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of Jenkins
#
# 1 - The Helm operation to do during deploy
#     - install (default)
#     - upgrade
# ==============================================================================

# Internal parameters

# Jenkins version: 2.249.3

HELM_CHART_VERSION=3.0.2

# Stop immediately if any of the deployments fail
trap errorHandler ERR

OPERATION=${1:-install}

checkAppName "jenkins"

echoHeader "Deploying the Jenkins Groupware Server (${JENKINS_APP_NAME})"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkStorageClass "jenkins"

checkFQN "jenkins" "${JENKINS_APP_NAME}"

checkCertificate "jenkins"

# Defaulting to 5 GB PVC size, if not set
cexport JENKINS_PVC_SIZE "5Gi"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "jenkins"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml
processTemplate chart-values-jobs.yaml
processTemplate chart-values-agent-pod-templates.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${JENKINS_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml

# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

# Dynamically combining the email (smtp) settings
CHART_VALUES_GIT_CREDENTIALS_CLAUSE=""
if [[ ${JENKINS_MAIN_GIT_ID} ]]
then
    processTemplate chart-values-git-credentials.yaml
    CHART_VALUES_GIT_CREDENTIALS_CLAUSE="--values ${TMP_DIR}/chart-values-git-credentials.yaml"
fi


# Dynamically combining the email (smtp) settings
CHART_VALUES_MAILER_CLAUSE=""
if [[ ${SMTP_ENABLED} == "true" ]]
then
    processTemplate chart-values-mailer.yaml
    CHART_VALUES_MAILER_CLAUSE="--values ${TMP_DIR}/chart-values-mailer.yaml"
fi

# Dynamically combining the test build job (if needed)
CHART_VALUES_TEST_JOB_CLAUSE=""
if [[ ${JENKINS_MAIN_GIT_TEST_REPO_PATH} ]]
then
    processTemplate chart-values-jobs-test.yaml
    CHART_VALUES_TEST_JOB_CLAUSE="--values ${TMP_DIR}/chart-values-jobs-test.yaml"
fi

helm repo add jenkins https://charts.jenkins.io
helm repo update

helm ${OPERATION} ${JENKINS_APP_NAME} jenkins/jenkins \
    --namespace ${JENKINS_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml \
    --values ${TMP_DIR}/chart-values-jobs.yaml \
    --values ${TMP_DIR}/chart-values-agent-pod-templates.yaml \
    ${CHART_VALUES_GIT_CREDENTIALS_CLAUSE} \
    ${CHART_VALUES_TEST_JOB_CLAUSE} \
    ${CHART_VALUES_MAILER_CLAUSE}

# ------------------------------------------------------------

if [[ "${JENKINS_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing a dedicated TLS certificate-request"

    applyTemplate certificate.yaml
else
    # A cluster-level, wildcard cert needs to be replicated into the namespace
    if [[ "${CLUSTER_CERT_SECRET_NAME}" ]]
    then
        deleteKubeObject "secret" "cluster-fqn-tls" "${JENKINS_APP_NAME}"
        applyTemplate cluster-fqn-tls-secret.yaml
    fi
fi

# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml

# ------------------------------------------------------------
echoSection "Jenkins has been installed on your cluster"


if [[ ${OPERATION} == "install" ]]
then

    # Deploying the backup profile if possible

    DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${JENKINS_APP_NAME})"

    if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
    else
        echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
    fi

fi