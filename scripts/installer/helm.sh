#!/usr/bin/env bash

#-------------------------------------------------------------------------------
#
# Helper script for installing Helm on a Linux machine.
#
# Uses the binary distribution downloaded directly from get.helm.sh.
#
# Requires root since it tries to install the binary into /usr/local/bin
#
#-------------------------------------------------------------------------------

function hr() {
    echo "----------------------------------------------"
}

function checkResult() {

    if [[ $? != 0 ]]
    then
        echo "${1} failed"
        exit 1
    fi
}
# ------------------------------------------------------------
# Parametrization

HELM_VERSION=2.16.1

# ------------------------------------------------------------
# Installation

# Stop immediately if any of the operations fail
set -e

cd /tmp

echo
hr
echo "Downloading Helm ${HELM_VERSION} from get.helm.sh"
hr

wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz

checkResult "Download"


echo
hr
echo "Unpacking the Helm archive"
hr

tar -zxvf helm-v${HELM_VERSION}-linux-amd64.tar.gz

checkResult "Unpacking"

echo
hr
echo "Moving the Helm binary to /usr/local/bin (needs root)"
hr

sudo mv linux-amd64/helm /usr/local/bin/helm

checkResult "Installation of the binary"


echo
echo
echo "SUCCESS"
echo