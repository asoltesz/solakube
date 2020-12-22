#
# Executes a PGO client command in the pgo-client pod
#

# Complex parametrization is not possible to pass via kubectl
# (double quoted parameters mishandled, at least with the PGO client)
# so we need to put the command into a file and upload it to the container
echo "pgo $@" > /tmp/cmd.sh
chmod +x /tmp/cmd.sh
copyFileToPod "name=pgo-client" "pgo" /tmp/cmd.sh /tmp/cmd.sh

echo "PGO command to be executed"
echo "--------------"
echo "pgo $@"
echo "--------------"

# Executing the uploaded command script
execInPod "name=pgo-client" "pgo" "bash /tmp/cmd.sh"

return $?
