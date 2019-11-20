#!/usr/bin/env bash


ALL_SATISFIED=0

#-----------------------------------------
# Helm
#-----------------------------------------

HELM_VERSION="$(helm --version)"

if [[ $? = 0 ]]
then
    echo "Helm version: ${HELM_VERSION}"
else
    echo "Helm not found"
    ALL_SATISFIED=1
fi


#-----------------------------------------
# Ansible
#-----------------------------------------

ANSIBLE_VERSION="$(ansible --version)"

if [[ $? = 0 ]]
then
    echo "Ansible version: ${ANSIBLE_VERSION}"
else
    echo "Ansible not found"
    ALL_SATISFIED=1
fi

#-----------------------------------------
# Terraform
#-----------------------------------------

TERRAFORM_VERSION="$(terraform --version)"

if [[ $? = 0 ]]
then
    echo "Terraform version: ${TERRAFORM_VERSION}"
else
    echo "Terraform not found."
    ALL_SATISFIED=1
fi



#--------------------------------------
exit ${ALL_SATISFIED}