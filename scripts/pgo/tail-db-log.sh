#
# Tails the PostgreSQL database logs on the primary.
#
# 1 - Name of the database cluster (e.g.: "default")
# 2 - Other selectors (defaults to "role=master")
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
# PGO Pods use UTC timezone and an English locale for logfile naming
DAY=$(TZ=UTC LC_ALL=en_US.utf8 date +"%a")

echo "Logging PG output of pod: ${DB_POD}"
echo "----------------------------------------"

kubectl exec ${DB_POD} -n pgo -- tail -f /pgdata/${DB_CLUSTER}/pg_log/postgresql-${DAY}.log
