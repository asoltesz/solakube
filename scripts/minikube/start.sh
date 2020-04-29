#!/usr/bin/env bash
# ------------------------------------------------------------
#
# Creates or starts a local cluster for testing SolaKube features
#
# If it doesn't exist yet, it creates it.
# ------------------------------------------------------------

shift

minikube start --kubernetes-version="v1.15.11" --vm-driver="kvm2" $@

# When debugging is needed
# --alsologtostderr -v=5

# Deploy ingress
minikube addons enable ingress
minikube addons enable ingress-dns