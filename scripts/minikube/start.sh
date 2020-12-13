#!/usr/bin/env bash
# ------------------------------------------------------------
#
# Creates or starts a local cluster for testing SolaKube features
#
# If it doesn't exist yet, it creates it.
# ------------------------------------------------------------

shift

KUBERNETES_VERSION="v1.19.4"

echoSection "Starting minikube with Kubernetes ${KUBERNETES_VERSION}"

# Docker based Minikube driver backend
minikube start \
    --kubernetes-version="${KUBERNETES_VERSION}" \
    --feature-gates="VolumeSnapshotDataSource=true" \
    --driver="docker" \
    --disk-size=20g
    $@


# When debugging is needed
# --alsologtostderr -v=5

# Deploy ingress
minikube addons enable ingress
minikube addons enable metrics-server
#minikube addons enable ingress-dns

minikube dashboard