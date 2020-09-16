# Redmine

Redmine is a lightweight issue management software that can be used for many purposes, including these:
- General Task Management (Project hierarchies, Task hierarchies)
- Software Development issue management (bugs, features, SCM connections...etc)
- Documentation & Knowledge base (wikis)

Features in detail on the [Redmine project website](https://redmine.org).

Supported version: 4.1.1

# Dependencies

You need to have a Postgres database cluster deployed on your k8s cluster or as an external service. See the [Postgres page](postgres.md) for supported deployment options.  

# Configuration

The following variables control the Redmine deployment done by SolaKube:

## variables.sh

Basic Redmine variables:

~~~
#
# The password for the 'redmine' user of Redmine (the main administrative user).
#
export REDMINE_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

#
# The email address for the 'admin' user of Redmine (the main administrative user).
#
export REDMINE_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

#
# The password for the 'admin' DB user in Postgres that has permissions
# for the data stored in the 'redmine' database which is the storage place
# for all relational data of Redmine
#
export REDMINE_DB_PASSWORD="${SK_ADMIN_PASSWORD}"

# The size of the persistent storage for the application
# export REDMINE_PVC_SIZE="3Gi"

# Whether the built-in backup profile (Velero) can be deployed
export REDMINE_BACKUP_ENABLED="Y"
~~~

In case you want to have email notifications from Redmine, have the SMTP_xxx parameters configured:

~~~
export SMTP_ENABLED="true"
...
~~~


# Deployment

In case the deployment is part of the initial cluster build (sk build), set the appropriate deployer flag before building the cluster:

~~~
export SK_DEPLOY_REDMINE="Y"
~~~

In case of a separate deployment, manually execute the deployer :

~~~
sk deploy redmine
~~~ 

This will:
- Create a Postgres database called 'redmine' and a database user that has
  access to it
- Deploys Redmine on the cluster with a Helm chart
- Allocates a persistent volume for Redmine files
- Requests a certificate for the ingress if necessary

# Post-Installation settings

The 'admin' user can administer/configure your Redmine instance.

# Notes

## Requested resources 

The requested resources are as follows (in chart-values.yaml):

~~~
resources:
    redmine:
        requests:
            cpu: 200m
            memory: 512Mi
~~~
Raise these resources in case you need it.

Limits are not defined by default.

