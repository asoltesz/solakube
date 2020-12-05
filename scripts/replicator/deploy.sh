#!/usr/bin/env bash

# ==============================================================================
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of pgAdmin
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

REPLICATOR_VERSION=2.0.1

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace "replicator"

# ------------------------------------------------------------
echoSection "Installing replicator v${REPLICATOR_VERSION}"

kubectl apply -f rbac.yaml \
    -n replicator

kubectl apply -f deployment.yaml \
    -n replicator

# Allowing Replicator to finish initializing before any replicatable content
# could appear in the cluster
sleep 60

# ------------------------------------------------------------
echoSection "Replicator has been installed on your cluster"

