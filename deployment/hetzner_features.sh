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

# Stop immediately if any of the deployments fail
set -e

# ------------------------------------------------------------------------------

echo "-------------------------------------------------------------------------"
echo "Validating parameters"
echo "-------------------------------------------------------------------------"


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

echo "-------------------------------------------------------------------------"
echo "Creating HETZNER_CLOUD_TOKEN secret"
echo "-------------------------------------------------------------------------"

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

echo "-------------------------------------------------------------------------"
echo "Installing HETZNER cloud controller with networks driver"
echo "-------------------------------------------------------------------------"

kubectl apply -f https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/master/deploy/v1.4.0-networks.yaml


echo "-------------------------------------------------------------------------"
echo "Installing HETZNER Floating IP support"
echo "-------------------------------------------------------------------------"

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


echo "-------------------------------------------------------------------------"
echo "Installing HETZNER storage/volume support"
echo "-------------------------------------------------------------------------"


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

echo "-------------------------------------------------------------------------"
echo "SUCCESS: All Hetzner features have been installed into your cluster."
echo "-------------------------------------------------------------------------"
