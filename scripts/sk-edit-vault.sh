#!/usr/bin/env bash

#
# Edits the Ansible Vault created for secrets handled by Ansible
#

findAnsibleProjectDir

cd ${ANSIBLE_PROJ_DIR}

export EDITOR=nano && \
ansible-vault edit group_vars/all/vault.yml