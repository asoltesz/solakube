# NextCloud Groupware Server

NextCloud is a groupware server (files, contacts, calendars, chat) that also provides you with the ability for online, collaborative office document editing.  

SolaKube supports the simplified deployment of NextCloud on your cluster with automatic creation of a Postgres database for it.

NextCloud is currently the most fully-featured OSS groupware server that you can run on your own infrastructure and has proper integrations not only with Android clients but Linux desktops as well.

Supported version: 18 (NextCloud Hub)

# Dependencies

You need to have a Postgres database cluster deployed on your k8s cluster or as an external service. See the [Postgres page](postgres.md) for supported deployment options.  

# Configuration

The following variables control the NextCloud deployment done by SolaKube:

## variables.sh

Basic Nextcloud variables:

~~~
# The password for the 'admin' user of Nextcloud (the main administrative user).
export NEXTCLOUD_ADMIN_PASSWORD="xxx"

# The password for the 'nextcloud' DB user in Postgres.
export NEXTCLOUD_DB_PASSWORD="xxx"
~~~

In case you want to have email notifications from Nextcloud, have the SMTP_xxx parameters configured:

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
export SK_DEPLOY_NEXTCLOUD="Y"
~~~

In case of a separate deployment, manually execute the deployer :

~~~
sk deploy nextcloud
~~~ 

This will:
- Create a Postgres database called 'nextcloud' and a database user that has
  access to it
- Deploys NextCloud on the cluster with a Helm chart
- Allocates a persistent volume for Nextcloud files
- Requests a certificate for the ingress if necessary

# Post-Installation settings

The 'admin' user can install and configure your Nextcloud instance.

## OnlyOffice

Nextcloud has built-in support for running the free (but connection limited) OnlyOffice document server by 2 Nextcloud applications (plugins). They are called 'Community Document Server' (OnlyOffice server component) and 'ONLYOFFICE' (integrates the UI of the OnlyOffice web editors into the NextCloud UI).

However, the default NextCloud php configuration will make the Community Document Server application download fail, so a manual installation is needed instead of just clicking on the admin UI.

Steps:
- Login to your NextCloud pod
- Download the binary from the [Document Server Releases](https://github.com/nextcloud/documentserver_community/releases). Version 0.1.5 is the current version as the time of this writing.
- Extract the application package
- Enable the application on the UI

Steps with sample commands (correct the pod name to your own):

~~~
# Switch to the nextcloud namespace
sk ns nextcloud

# Get the name of your nextcloud pod
kubectl get pods

# Get a remote shell into the NextCloud pod
kubectl exec -it nextcloud-66df5bdf6f-fk9zh /bin/bash

# Enter the NextCloud applications (plugins) folder
cd /var/www/html/apps

# Download the server binary
curl https://github.com/nextcloud/documentserver_community/releases/download/v0.1.5/documentserver_community.tar.gz -L --output docserver.tar.gz 

# Extract the binary package (a subfolder will be created)
tar -xzf docserver.tar.gz 

# Delete the download package (not needed anymore)
rm docserver.tar.gz
~~~

After this, go to the Applications section of the Nextcloud UI and enable the Community Document Server application.

Also, install the 'ONLYOFFICE' application (the UI parts).

# Notes

## Uploading big files

By default the NextCloud Docker container is configured for accepting files up to 512 MB. The Kubernetes Ingress is also configured for this size by SolaKube

The Nextcloud clients can upload files much bigger than this, since they upload in much smaller chunks.

In case you need to upload huge files via the web inteface:
- check the [Nextcloud Documentation for Uploading Big Files](https://docs.nextcloud.com/server/18/admin_manual/configuration_files/big_file_upload_configuration.html?highlight=big%20files)
- modify the ingress definition to allow bigger uploads
