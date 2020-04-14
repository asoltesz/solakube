#!/usr/bin/env bash

# ==============================================================================
# Sets the current working context namespace in kubectl.
#
# 1 - The namespace to be made the active/current
#
# ==============================================================================



kubectl config set-context --current --namespace=${1}
