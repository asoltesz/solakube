export INSECURE_REGISTRY=true
export BASIC_AUTH=admin:${REGISTRY_ADMIN_PASSWORD}

./docker_reg_tool http://${REGISTRY_APP_NAME}-docker-registry:5000 ${COMMAND} ${REPO} ${TAG}

rm -R /regtool.sh
