#!/usr/bin/env bash

#-------------------------------------------------------------------------------
#
# Downloads the cluster settings from Rancher and place them into ~/.kube/config.
#
#-------------------------------------------------------------------------------

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
    echo "-----------------------------------------------------"
    echo ${1}
    echo "-----------------------------------------------------"
    echo

}

# ------------------------------------------------------------
# Stop immediately if any of the operations fail
set -e

echo "Loading variables"

echoSection "Validating parameters"


if [[ ! ${RANCHER_API_TOKEN} ]]
then
    echo "ERROR: RANCHER_API_TOKEN env var is not defined."

    echo "Please, define it with the token generated in Rancher in the form of 'token-iu6fg:lhvhildfkgjdlfkgjdfdfágládfdfgpxp5vb'."

    exit 1
fi

if [[ ! ${RANCHER_CLUSTER_ID} ]]
then
    echo "ERROR: RANCHER_CLUSTER_ID env var is not defined."

    echo "Please, define it with the cluster id of the Terraform output in the form of 'c-hmmwr'. Originally, it was printed by apply-cluster.sh."

    exit 1
fi

if [[ ! ${RANCHER_HOST} ]]
then
    echo "ERROR: RANCHER_HOST env var is not defined."

    echo "Please, define it with the FQN of your Rancher install in the form of 'rancher.example.com'. (Host must be accessible via https)"

    exit 1
fi


# ------------------------------------------------------------

# Backing up the current Kubectl config

if [[ -f ~/.kube/config ]]
then
    echo "Backing up current kubectl config"
    TS="$(date --iso-8601=seconds)"
    mv ~/.kube/config ~/.kube/config_${TS}
fi

echoSection "Downloading the new Kubectl config file"

curl -u "${RANCHER_API_TOKEN}" \
-X POST \
-H 'Accept: application/json' \
-H 'Content-Type: application/json' \
-d '{}' \
-o ~/.kube/config \
"https://${RANCHER_HOST}/v3/clusters/${RANCHER_CLUSTER_ID}?action=generateKubeconfig"

# The response in JSON is with encoded characters and extra unneeded content.
# - Needs to be decoded
# - only the text in the "config" attribute is needed
#

sed -i 's/{"baseType":"generateKubeConfigOutput","config":"//g' ~/.kube/config
sed -i 's/\\n/\n/g' ~/.kube/config
sed -i 's/\\"/"/g' ~/.kube/config
sed -i 's/","type":"generateKubeConfigOutput"}//g' ~/.kube/config
sed -e '1h;2,$H;$!d;g' -e 's/\\\\\n      //g' ~/.kube/config > /tmp/kubeconfig
mv /tmp/kubeconfig ~/.kube/config

# ------------------------------------------------------------------------------

echoSection "Testing kubectl with a node query"

kubectl get nodes

echo "---------------------------------------------------"
echo
echo "SUCCESS. "
echo
echo "Check the above node list, it should contain the nodes of the new cluster."
echo

