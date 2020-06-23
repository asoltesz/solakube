#
# Executes a PGO client command in the pgo-client container
#

## Get a shell in the pgo client container
#kcl get pods -n pgo
#kcl exec -it pgo-client-bb647bbcd-tvqnz -n pgo -- /bin/bash
#
## Namespace beállítása a parancsokhoz
#export PGO_NAMESPACE=pgo
#
## Új DB cluster létrehozása
#pgo create cluster hippo
#
## Clusterben a postgres admin user password-jének reset-elése
#pgo update user hippo --username=postgres --password=solasola
#
## Egy futó feladat figyelése
#pgo watch workflow <workflow>


CLIENT_POD=$(kubectl get pods \
              --selector=name=pgo-client \
              --output=jsonpath={.items..metadata.name} \
              --namespace pgo \
              --no-headers
            )
kubectl exec -it ${CLIENT_POD} -n pgo -- /bin/bash
