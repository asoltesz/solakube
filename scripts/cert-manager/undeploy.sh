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

echoHeader "Uninstalling Cert-Manager from your cluster"

deleteHelmRelease cert-manager

deleteNamespace cert-manager
deleteNamespace cert-manager-test

# ------------------------------------------------------------
echoSection "SUCCESS: Cert-Manager has been uninstalled from your cluster."

