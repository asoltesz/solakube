#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Complete build process for a cluster from zero to completely provisioned
# and all needed applications/components installed.
#
# Environment variables (see variables.sh):
#
# - SK_DEPLOY_***
#   Whether to deploy a certain *** component to the cluster.
#   See templates/variables.sh and variables.md for possible values.
# ------------------------------------------------------------------------------

#
# Creating/updating the cluster
#
. ${SK_SCRIPT_HOME}/sk-apply.sh -auto-approve
checkResultExit "Terraform cluster create/update"

#
# Downloading the KubeCtl settings file
#
. ${SK_SCRIPT_HOME}/sk-dl-config.sh
checkResultExit "Downloading the Kubectl config"

#
# Waiting for the cluster nodes to provision
#
. ${SK_SCRIPT_HOME}/sk-wait-for-rancher.sh
checkResultExit "Waiting for successful Rancher cluster provisioning"

#
# Installing Hetzner-specific components like fip-controller and volumes
# ------------------
. ${SK_SCRIPT_HOME}/sk deploy hetzner
checkResultExit "Deploying Hetzner-cloud support components"
#

#
# Installing the Rook/Ceph storage cluster
# ------------------
if [[ "${SK_DEPLOY_ROOK_CEPH}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy rook-ceph
    checkResultExit "Deploying a Rook/Ceph storage cluster"
fi

#
# Installing Helm's Tiller
# ------------------
. ${SK_SCRIPT_HOME}/sk deploy helm-tiller
checkResultExit "Deploying Helm's Tiller to the cluster"

#
# Installing Cert-Manager
# ------------------
if [[ "${SK_DEPLOY_CERT_MANAGER}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy cert-manager
    checkResultExit "Deploying Cert-Manager to the cluster"
fi

#
# Installing Replicator for cert distribution if wildcard certificates
# were requested
# ------------------
if [[ "${SK_DEPLOY_CERT_MANAGER}" == "Y" ]] && [[ "${LETS_ENCRYPT_DEPLOY_WC_CERT}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy replicator
    checkResultExit "Deploying Replicator to the cluster"
fi

#
# Installing PostgreSQL DBMS
# ------------------
if [[ "${SK_DEPLOY_POSTGRES}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy postgres
    checkResultExit "Deploying PostgreSQL to the cluster"
fi

#
# Installing pgAdmin
# ------------------
if [[ "${SK_DEPLOY_PGADMIN}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy pgadmin
    checkResultExit "Deploying pgAdmin to the cluster"
fi


#
# Installing the (plain) Docker Registry
# ------------------
if [[ "${SK_DEPLOY_DOCKER_REGISTRY}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy docker-registry
    checkResultExit "Deploying Docker Registry to the cluster"
fi

#
# Installing OpenLDAP
# ------------------
if [[ "${SK_DEPLOY_OPENLDAP}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy openldap
    checkResultExit "Deploying OpenLDAP to the cluster"
fi
