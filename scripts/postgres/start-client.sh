#!/usr/bin/env bash

# ==============================================================================
# Starts a Postgres-Client container in a namespace
#
# 1 - namespace
# ==============================================================================

namespace=${1:-postgres}

kubectl run postgres-client \
    -i --rm --tty --restart='Never' \
    --namespace ${namespace} \
    --image="docker.io/bitnami/postgresql:12.5.0-debian-10-r16" \
    --command \
    -- /bin/bash

# Example PSQL execution (loading a dump copied into the container)
#
# psql --host=limes.pgo -U limes -d limes -f /tmp/dump.sql
#