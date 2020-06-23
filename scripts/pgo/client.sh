#
# Executes a PGO client command in the pgo-client pod
#

# Querying the PGO client CLI pod
CLIENT_POD=$(kubectl get pods \
              --selector=name=pgo-client \
              --output=jsonpath={.items..metadata.name} \
              --namespace pgo \
              --no-headers
            )

if [[ ! ${CLIENT_POD} ]]
then
    echo "ERROR: PGO client CLI pod not found"
    exit 1
fi

# Complex parametrization is not possible to pass via kubectl
# (double quoted parameters mishandled, at least with the PGO client)
# so we need to put the command into a file and upload it to the container
echo "pgo $@" > /tmp/cmd.sh
chmod +x /tmp/cmd.sh
kubectl cp /tmp/cmd.sh ${CLIENT_POD}:/tmp/cmd.sh -n pgo

echo "PGO command to be executed"
echo "--------------"
echo "pgo $@"
echo "--------------"

# Executing the uploaded command script
kubectl exec -it ${CLIENT_POD} -n pgo -- bash /tmp/cmd.sh

exit $?
