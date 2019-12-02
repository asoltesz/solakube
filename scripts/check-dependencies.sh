#!/usr/bin/env bash
# ------------------------------------------------------------
#
# Checks if all necessary software that are needed by the scripts (dependencies)
# are present.
#
# WARNING: It does not (yet) check necessary minimum and maximum versions
#
# ------------------------------------------------------------

function hr() {
    echo "----------------------------------------------"
}

ALL_PRESENT=0


echo "Checking all dependencies and printing their version information"


#-----------------------------------------
# Helm
#-----------------------------------------
hr
echo "Helm"
hr

HELM_VERSION="$(helm version --client)"

if [[ $? = 0 ]]
then
    echo "Helm version: ${HELM_VERSION}"
else
    echo "Helm not found"
    ALL_PRESENT=1
fi


#-----------------------------------------
# Ansible
#-----------------------------------------
hr
echo "Ansible"
hr

ANSIBLE_VERSION="$(ansible --version)"

if [[ $? = 0 ]]
then
    echo "Ansible version: ${ANSIBLE_VERSION}"
else
    echo "Ansible not found"
    ALL_PRESENT=1
fi

#-----------------------------------------
# Terraform
#-----------------------------------------
hr
echo "Terraform"
hr

TERRAFORM_VERSION="$(terraform --version)"

if [[ $? = 0 ]]
then
    echo "Terraform version: ${TERRAFORM_VERSION}"
else
    echo "Terraform not found."
    ALL_PRESENT=1
fi



#--------------------------------------
hr

if [[ "${ALL_PRESENT}" == 0 ]]
then
    echo "RESULT: All dependencies are present"
else
    echo "RESULT: One or more dependencies are missing"
fi

hr


exit ${ALL_PRESENT}