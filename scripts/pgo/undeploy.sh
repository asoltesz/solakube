#!/usr/bin/env bash

# ==============================================================================
#
# Deletes the CrunchyData Postgres Operator from the cluster
#
# WARNING: Doesn't remove the already installed PostgreSQL clusters if
#          they are in separate namespaces.
#          Use the pgo client for that before removing pgo itself
# ==============================================================================

deleteNamespace "pgo"