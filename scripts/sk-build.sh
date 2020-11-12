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
# Minikube and other hand-built clusters don't need Terraform, only
# a proper Hetzner cluster type
#
if [[ ${SK_CLUSTER_TYPE} == "hetzner" ]]
then
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

else
    echo "Base cluster building skipped for type: ${SK_CLUSTER_TYPE}"
fi

#
# Installing the Velero Disaster Recovery tool
# ------------------
if [[ "${SK_DEPLOY_VELERO}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy velero
    checkResultExit "Deploying the Velero Disaster Recovery tool to the cluster"
fi

#
# Installing the Rook/Ceph storage cluster
# ------------------
if [[ "${SK_DEPLOY_ROOK_CEPH}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy rook-ceph
    checkResultExit "Deploying a Rook/Ceph storage cluster"
fi

#
# Installing the OpenEBS storage provisioner
# ------------------
if [[ "${SK_DEPLOY_OPENEBS}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy openebs
    checkResultExit "Deploying OpenEBS storage provisioner"
fi

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
# Installing BackBlaze B2 support
# ------------------
if [[ "${SK_DEPLOY_B2S3}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy b2s3
    checkResultExit "Deploying BackBlaze B2 support to the cluster"
fi

#
# Installing PostgreSQL DBMS
# ------------------
if [[ "${SK_DEPLOY_PGS}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy pgs
    checkResultExit "Deploying PostgreSQL (simple) to the cluster"
fi

#
# Installing CrunchyData Postgres Operator + a managed PostgreSQL cluster
# ------------------
if [[ "${SK_DEPLOY_PGO}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy pgo
    checkResultExit "Deploying CrunchyData Postgres Operator to the cluster"
fi

#
# Installing Mailu Email Services
# ------------------
if [[ "${SK_DEPLOY_MAILU}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy mailu
    checkResultExit "Deploying Mailu Email Services to the cluster"
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
# Installing Nextcloud
# ------------------
if [[ "${SK_DEPLOY_NEXTCLOUD}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy nextcloud
    checkResultExit "Deploying NextCloud to the cluster"
fi

#
# Installing OpenLDAP
# ------------------
if [[ "${SK_DEPLOY_OPENLDAP}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy openldap
    checkResultExit "Deploying OpenLDAP to the cluster"
fi

#
# Installing WordPress
# ------------------
if [[ "${SK_DEPLOY_WORDPRESS}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy wordpress
    checkResultExit "Deploying Wordpress to the cluster"
fi

#
# Installing Gitea
# ------------------
if [[ "${SK_DEPLOY_GITEA}" == "Y" ]]
then
    . ${SK_SCRIPT_HOME}/sk deploy gitea
    checkResultExit "Deploying Gitea to the cluster"
fi
