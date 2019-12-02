#!/usr/bin/env bash

#
# Installs Basic Cluster features that are typically needed in all clusters.
#
# - Helm's Tiller
#

# Stop immediately if any of the deployments fail
set -e

# ------------------------------------------------------------

function checkResult() {

    if [[ $? != 0 ]]
    then
        echo "${1} failed"
        exit 1
    fi
}


function echoSection() {

    echo
    echo "-------------------------------------------------------------------------"
    echo ${1}
    echo "-------------------------------------------------------------------------"
    echo

}
# ------------------------------------------------------------
echoSection "Installing Helm's server-side component: Tiller"

kubectl create serviceaccount tiller \
    --namespace kube-system

kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --upgrade --service-account tiller

echo "Waiting for the Tiller pod to be created"
sleep 15s

echoSection "Helm's Tiller has been installed in the cluster and inited"

