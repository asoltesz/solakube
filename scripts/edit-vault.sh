#!/usr/bin/env bash

#
# Edits the Ansible Vault created for secrets handled by Ansible
#

cd ../ansible

export EDITOR=nano && \
ansible-vault edit group_vars/all/vault.yml