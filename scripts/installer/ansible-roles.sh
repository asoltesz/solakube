#!/usr/bin/env bash

#
# Installs custom Ansible roles that will be needed during the cluster
# node VM provisioning
#

# Go to the root of the project
cd ../..

# install requirements
ansible-galaxy install -r ansible/requirements.yml