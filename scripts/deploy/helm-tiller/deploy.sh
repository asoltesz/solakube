#!/usr/bin/env bash

#
# Installs Basic Cluster features that are typically needed in all clusters.
#
# - Helm's Tiller
#

# Stop immediately if any of the deployment commands fail
trap errorHandler ERR


echoHeader "Installing Helm's server-side component: Tiller"

kubectl create serviceaccount tiller \
    --namespace kube-system

kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --upgrade --service-account tiller

echo "Waiting for the Tiller pod to be available for installs"

sleep 45s

echoSection "Helm's Tiller has been installed in the cluster and inited"

