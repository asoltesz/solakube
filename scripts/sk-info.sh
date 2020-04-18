#!/usr/bin/env bash

# Information about the current SolaKube project

#-------------------------------------------------------------------------------
# Displays variables/settings about the current environment
#
# Parameters:
# 1 - Extended info (Y/N) - default value: N
#
#-------------------------------------------------------------------------------

EXTENDED=$1

echo "-------------------------------------------------------------------------"
echo "Information about the ${SK_CLUSTER} cluster"
echo "-------------------------------------------------------------------------"
echo "Scripts folder (SK_SCRIPT_HOME):               ${SK_SCRIPT_HOME}"
echo "-------------------------------------------------------------------------"


if [[ "${EXTENDED}" != "Y" ]]
then
    echo
    exit 0;
fi


#
# Extended information
#

# echo "SolaKube version:                              ${SK_VERSION}"

echo "Default storage class (DEFAULT_STORAGE_CLASS):   ${DEFAULT_STORAGE_CLASS}"
echo "-------------------------------------------------------------------------"


echo