#!/usr/bin/env bash

# ==============================================================================
#
# Executes an SQL script in PostgreSQL
#
# 1 - The path of the script to be executed
# ==============================================================================

# Internal parameters


# Stop immediately if any of the deployments fail
trap errorHandler ERR

SQL_SCRIPT_FILE=$1

echo "SQL script file: ${SQL_SCRIPT_FILE}"

executePostgresAdminScript ${SQL_SCRIPT_FILE}

