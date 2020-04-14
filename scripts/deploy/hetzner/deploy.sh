#!/usr/bin/env bash

#
# Installs Hetzner cloud support features into a Kubernetes cluster that is
# running on Hetzner Cloud virtual machines.
#
# - Hetzner Cloud Controller Manager (hcloud-cloud-controller-manager)
# - Hetzner Floating IP Controller (fip-controller)
# - Hetzner Volume support (csi-driver)
#
# It assumes that you have already configured Kubectl to your cluster.
#
# Expected variables: See the "Validating parameters" section
#


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying Hetzner specific cloud-support components"

#
# The Hcloud Fip Controller version (branch/tag on GitHub)
#
export HETZNER_FIP_CTRL_VERSION=v0.3.0

#
# The Hetzner CSI Driver version (branch/tag on GitHub)
#
export HETZNER_CSI_DRIVER_VERSION=v1.1.5

#
# The Hetzner Cloud Controller Manager version (branch/tag on GitHub)
#
export HETZNER_CLOUD_CTRL_VERSION=v1.4.0


# ------------------------------------------------------------
echoSection "Validating parameters"


if [[ ! ${HETZNER_CLOUD_TOKEN} ]]
then
    echo "ERROR: HETZNER_CLOUD_TOKEN env var is not defined."
    echo "Please define it with the token you created the cluster with."
    exit 1
fi

if [[ ! ${HETZNER_FLOATING_IP} ]]
then
    echo "ERROR: The HETZNER_FLOATING_IP env var is not defined. Cannot continue."
    echo "Please define it with the IP you got from the Terraform output."
    exit 1
fi


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "hetzner"

export DEPLOY_NAMESPACE="NOT_SPECIFIED"

# ------------------------------------------------------------
echoSection "Creating HETZNER_CLOUD_TOKEN secret"

applyTemplate cloud-controller-secret.yaml


# ------------------------------------------------------------
echoSection "Installing HETZNER cloud controller with networks driver"

kubectl apply -f  \
    https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/${HETZNER_CLOUD_CTRL_VERSION}/deploy/${HETZNER_CLOUD_CTRL_VERSION}-networks.yaml


# ------------------------------------------------------------
echoSection "Installing HETZNER Floating IP support"

echo "Patching canal to allow scheduling"

kubectl -n kube-system patch ds canal \
  --type json -p \
    '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'

echo "Waiting until the canal patch takes effect"
sleep 10s

defineNamespace fip-controller

kubectl apply  \
    -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/${HETZNER_FIP_CTRL_VERSION}/deploy/rbac.yaml

applyTemplate fip-controller-config.yaml

applyTemplate fip-controller-deployment.yaml


# ------------------------------------------------------------
echoSection "Re-distributing fip-controller pods"

echo "Waiting 20 seconds so that fip-controller pods are created"

sleep 20s

#
# For some reason, all 3 fip-controller pods get scheduled on the same node
# by default which defeats the purpose and makes fip reassignment much slower
# than it should be
#
# fip-controller pods should be distributed on 3 different nodes
#
# We try to redistribute by killing the default pods. This usually results at least
# in a 2-node distribution in a 3-node set
#
echo "Killing all fip-controller pods to get a better node distribution"

for podName in $(kubectl get pods --no-headers --namespace="fip-controller" | awk '{print $1}');
do
    # echo "Deleting pod: ${podName}"
    kubectl delete pods ${podName} --namespace="fip-controller"
    sleep 3
done

echo "Waiting for new fip-controller pods to stabilize"

sleep 10s

# ------------------------------------------------------------
echoSection "Installing HETZNER storage/volume support"

export DEPLOY_NAMESPACE="NOT_SPECIFIED"

applyTemplate csi-secret.yaml

kubectl apply  \
    -f https://raw.githubusercontent.com/hetznercloud/csi-driver/${HETZNER_CSI_DRIVER_VERSION}/deploy/kubernetes/hcloud-csi.yml

echo "Waiting for the CSI driver to initialize"
sleep 10

# ------------------------------------------------------------
echoSection "SUCCESS: All Hetzner features have been installed into your cluster."
