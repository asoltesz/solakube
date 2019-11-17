#!/usr/bin/env bash

#
# Creates an Ansible Vault for secrets handled by Ansible
#

cd ../ansible

export EDITOR=nano && \
ansible-vault create group_vars/all/vault.yml