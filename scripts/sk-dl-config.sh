#!/usr/bin/env bash

#-------------------------------------------------------------------------------
#
# Downloads the cluster settings from Rancher and place them into ~/.kube/config
# so that the administrator and deployer scripts can execute kubectl commands
# against the new cluster
#
#-------------------------------------------------------------------------------

backupKubeConfig() {

    if [[ -f ~/.kube/config ]]
    then
        echo "Backing up current kubectl config"
        TS="$(date --iso-8601=seconds)"
        mkdir -p ~/.kube/backup
        mv ~/.kube/config ~/.kube/backup/config_${TS}
    fi
}

downloadKubeConfig() {

    curl -u "${RANCHER_API_TOKEN}" \
    -X POST \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{}' \
    -o /tmp/kubeconfig \
    "https://${RANCHER_HOST}/v3/clusters/${RANCHER_CLUSTER_ID}?action=generateKubeconfig"

    if [[ $? == 0 ]]
    then
        echo "Download successful"
        return 0
    fi

    echo "Download failed"
    return 1
}

processKubeConfig() {

    # The response in JSON is with encoded characters and extra unneeded content.
    # - Needs to be decoded
    # - only the text in the "config" attribute is needed
    #

    sed -i 's/{"baseType":"generateKubeConfigOutput","config":"//g' /tmp/kubeconfig
    sed -i 's/\\n/\n/g' /tmp/kubeconfig
    sed -i 's/\\"/"/g' /tmp/kubeconfig
    sed -i 's/","type":"generateKubeConfigOutput"}//g' /tmp/kubeconfig
    sed -e '1h;2,$H;$!d;g' -e 's/\\\\\n      //g' /tmp/kubeconfig > /tmp/kubeconfig2
}

# ------------------------------------------------------------
# Stop immediately if any of the operations fail

echoSection "Validating parameters"


checkRancherAccessParams
if [[ $? != 0 ]]
then
    exit 1
fi

# ------------------------------------------------------------


echoHeader "Downloading the new Kubectl config file"

downloadKubeConfig
if [[ $? != 0 ]]
then
    exit 1
fi

processKubeConfig
if [[ $? != 0 ]]
then
    exit 1
fi

# Backing up the current/original Kubectl config
backupKubeConfig
if [[ $? != 0 ]]
then
    exit 1
fi

rm -rf ~/.kube/config
cp /tmp/kubeconfig2 ~/.kube/config

# Saving into a dedicated file as well for
rm -rf ~/.kube/config_${SK_CLUSTER}.yaml
cp /tmp/kubeconfig2 ~/.kube/config_${SK_CLUSTER}.yaml

# ------------------------------------------------------------------------------
