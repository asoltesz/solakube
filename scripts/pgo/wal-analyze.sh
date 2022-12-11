#
# Runs a "df" on the DB cluster to show WAL PVC usage.
#
# Lists the current WAL files of the primary in time-sorted order.
#
# Can be used to investigate WAL anomalies (e.g.: stuck WAL-archiving)
#
# 1 - Name of the database cluster (e.g.: "default")
# 2 - Other selectors for selecting the primary pod (defaults to "role=master")
#
trap stopped INT

function stopped() {
    echo "----------------------------------------"
    echo "log tailing stopped"
    exit 0
}

DB_CLUSTER=${1:-"default"}
EXTRA_SEL=${2:-"role=master"}

SEL="pg-cluster=${DB_CLUSTER}"
SEL="${SEL}$([[ -n ${EXTRA_SEL} ]] && echo ",")"
SEL="${SEL}${EXTRA_SEL}"

DB_POD=$(kubectl get pods \
              --selector=${SEL} \
              --output=jsonpath={.items..metadata.name} \
              --namespace pgo \
              --no-headers
            )

echo "Listing WAL files: ${DB_POD}"
echo "----------------------------------------"

kubectl exec ${DB_POD} -n pgo -- ls -latR /pgwal

echo
echo "-----------------------------------------------------------"
echo "Querying PVC usage of the ${DB_CLUSTER} database cluster"
echo "-----------------------------------------------------------"

. ${SK_SCRIPT_HOME}/pgo/exec.sh df ${DB_CLUSTER}

echo "-----------------------------------------------------------"
