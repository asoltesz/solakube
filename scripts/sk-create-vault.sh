#!/usr/bin/env bash

#
# Creates an Ansible Vault for secrets handled by Ansible
#

findAnsibleProjectDir

cd ${ANSIBLE_PROJ_DIR}

export EDITOR=nano && \
ansible-vault create group_vars/all/vault.yml