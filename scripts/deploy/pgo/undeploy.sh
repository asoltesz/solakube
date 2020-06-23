#!/usr/bin/env bash

# ==============================================================================
#
# Deletes the CrunchyData Postgres Operator from the cluster
#
# WARNING: Doesn't remove the already installed PostgreSQL clusters !!!
#          Use the pgo client for that before removing pgo itself
# ==============================================================================

export SCRIPTS_SUB_DIR=${SK_SCRIPT_HOME}/deploy/pgo

# Executing the script
. ${SCRIPTS_SUB_DIR}/deploy.sh uninstall
