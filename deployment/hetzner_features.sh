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

function echoSection() {

    echo
    echo "--------------------------------------------------------"
    echo ${1}
    echo "--------------------------------------------------------"
    echo

}


# Stop immediately if any of the deployments fail
set -e

# ------------------------------------------------------------------------------
echoSection "Validating parameters"


if [[ ! ${HETZNER_CLOUD_TOKEN} ]]
then
    echo "ERROR: HETZNER_CLOUD_TOKEN env var is not defined."
    echo "Please define it with the token you created the cluster with."
    exit 1
fi

if [[ ! ${FLOATING_IP} ]]
then
    echo "ERROR: The FLOATING_IP env var is not defined. Cannot continue."
    echo "Please define it with the IP you got from the Terraform output."
    exit 1
fi

# ------------------------------------------------------------------------------
echoSection "Creating HETZNER_CLOUD_TOKEN secret"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
    name: hcloud
    namespace: kube-system
stringData:
    token: "${HETZNER_CLOUD_TOKEN}"
    network: "default"
EOF

# ------------------------------------------------------------------------------
echoSection "Installing HETZNER cloud controller with networks driver"

kubectl apply -f https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/master/deploy/v1.4.0-networks.yaml


# ------------------------------------------------------------------------------
echoSection "Installing HETZNER Floating IP support"

kubectl -n kube-system patch ds canal --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'

kubectl create namespace fip-controller

kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/rbac.yaml

kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/deployment.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: fip-controller-config
  namespace: fip-controller
data:
  config.json: |
    {
      "hcloud_floating_ips": [ "${FLOATING_IP}" ],
      "node_address_type": "external"
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: fip-controller-secrets
  namespace: fip-controller
stringData:
  HCLOUD_API_TOKEN: ${HETZNER_CLOUD_TOKEN}
EOF

# ------------------------------------------------------------------------------
echoSection "Re-distributing fip-controller pods"

echo "Waiting 20 seconds so that fip-controller pods are created"

sleep 20s

# For some reason, all fip-controller pods get scheduled on the same node
# by default which defeats the purpose and makes fip reassignment much slower
# than it should be

echo "Killing all fip-controller pods to get a better node distribution"

for podName in $(kubectl get pods --no-headers --namespace="fip-controller" | awk '{print $1}');
do
    # echo "Deleting pod: ${podName}"
    kubectl delete pods ${podName}
    sleep 3
done

# ------------------------------------------------------------------------------
echoSection "Installing HETZNER storage/volume support"


cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: hcloud-csi
  namespace: kube-system
stringData:
  token: $HETZNER_CLOUD_TOKEN
EOF

kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/master/deploy/kubernetes/hcloud-csi.yml

# ------------------------------------------------------------------------------
echoSection "SUCCESS: All Hetzner features have been installed into your cluster."
