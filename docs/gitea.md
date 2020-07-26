# Gitea

Gitea is a lightweight GitHub clone, ideal for smaller development teams.

Supported version: 1.12.2

# Dependencies

You need to have a Postgres database cluster deployed on your k8s cluster or as an external service. See the [Postgres page](postgres.md) for supported deployment options.  

# Configuration

The following variables control the Gitea deployment done by SolaKube:

## variables.sh

Basic Gitea variables:

~~~
#
# The password for the 'gitea' user of Gitea (the main administrative user).
#
export GITEA_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

#
# The email address for the 'gitea' user of Gitea (the main administrative user).
#
export GITEA_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

#
# The password for the 'gitea' DB user in Postgres that has permissions
# for the data stored in the 'gitea' database which is the storage place
# for all relational data of Gitea
#
export GITEA_DB_PASSWORD="${SK_ADMIN_PASSWORD}"

# The size of the persistent storage for the application
# export GITEA_PVC_SIZE="3Gi"

# Whether the built-in backup profile (Velero) can be deployed
export GITEA_BACKUP_ENABLED="Y"
~~~

In case you want to have email notifications from Gitea, have the SMTP_xxx parameters configured:

~~~
export SMTP_ENABLED="true"
...
~~~

Make sure that you have the necessary Postgres parameters configured:

~~~
# PostgreSQL admin user (DBA, typically called 'postgres') password
export POSTGRES_ADMIN_PASSWORD="xxx"

# The namespace in which the Postgres service is installed or in which the
# postgres client pod can execute
export POSTGRES_NAMESPACE="postgres"

# The host name on which the Postgres service is available
export POSTGRES_SERVICE_HOST="postgres-postgresql.postgres"

~~~

# Deployment

In case the deployment is part of the initial cluster build (sk build), set the appropriate deployer flag before building the cluster:

~~~
export SK_DEPLOY_GITEA="Y"
~~~

In case of a separate deployment, manually execute the deployer :

~~~
sk deploy gitea
~~~ 

This will:
- Create a Postgres database called 'gitea' and a database user that has
  access to it
- Deploys Gitea on the cluster with a Helm chart
- Allocates a persistent volume for Gitea files
- Requests a certificate for the ingress if necessary

# Post-Installation settings

The 'gitea' user can administer/configure your Gitea instance.

# Notes

## Requested resources lowered

The requested resources slightly lowered compared to Helm chart defaults because a
bare-install, infrequently used Gitea doesn't actually need those resources and memory is 
especially precious:

~~~
resources:
    gitea:
        requests:
            cpu: 100m
            memory: 300Mi
~~~
Raise these resources in case you need it.

Limits have not been modified, left at relative high values.

