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

## Collabora Online Document Server and Document Editors

Nextcloud has built-in support for integrating with the CODE document server (Collabora Online Developer Edition) and the web-based document editors.

### Installing the document server

NextCloud can install the document server internally, into the Nextcloud pod.

This is not ideal from the scaling/scheduling perspective but it is the easiest to install.

Go to the Applications section of the Nextcloud UI and enable the "Collabora Online - Built-in CODE Server" application.

#### Standalone CODE Server

SolaKube includes a sample, standalone CODE deployer ("code") which installs the document server into its own namespace on your cluster and makes it accessible publicly. However, ATM, it is not usable due to unresolved security settings (see the [deployer docs](code.md)). 

### Installing the document editors

Go to the Applications section of the Nextcloud UI and enable the "Collabora Online" application.

Refresh the page and check if NextCloud installed AND enabled the application. Sometimes it gets installed but it remains in disabled state (as of NC 20.0.1).

Wait for the document server to start up (that may take several minutes). 

Go into the "Collabora Online" page in the Settings section and select the internal server option. If you can save the option, the internal server has properly started up and accessible.

### Document editing

After the above installation/setup steps, you should be able to edit ODF and Microsoft Office document files on the user interface of Nextcloud by clicking on the file in the Files app.

Refresh the Files app before your first try because it needs to know if the Collabora Online extension has been installed in the meantime (otherwise, it will just try to download your documents). 

# Administration

## Running occ commands in the container

The occ command can only be executed with the 'www-data' user.

In the container shell, switch the user to www-data:

~~~
su -s /bin/bash www-data
~~~ 

Then, you can run an occ command (e.g: a document reindex, as follows):

~~~
php /var/www/html/occ files:scan --all
~~~

# Notes

## Uploading big files

By default the NextCloud Docker container is configured for accepting files up to 512 MB. The Kubernetes Ingress is also configured for this size by SolaKube

The Nextcloud clients can upload files much bigger than this, since they upload in much smaller chunks.

In case you need to upload huge files via the web inteface:
- check the [Nextcloud Documentation for Uploading Big Files](https://docs.nextcloud.com/server/18/admin_manual/configuration_files/big_file_upload_configuration.html?highlight=big%20files)
- modify the ingress definition to allow bigger uploads
