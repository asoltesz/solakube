# Applications / Components

SolaKube supports the automated deployment for a limited set of applications.

Manually, you can deploy applications with the Rancher UI (from its catalogs) or with Helm.

SolaKube installers do a more complex/complete installation for the supported applications than a simple Helm chart can. 

These include:
- Ingress that handles the cluster-level wildcard certificate or a dedicated certificate managed by Cert-Manager
- Auto-creating a database for the application in the cluster-level Postgres DB service (PGO or Postgres-Simple DB clusters)
- Auto-selection of the most appropriate storage class for the application's persistent data
- Backup/restore profile with Velero
- Auto-creation of the admin user in the application
- Reasonable defaults for less-well-tuned Helm charts
- Application specific fine-tuning (e.g.: sync-client HTTPS settings for Nextcloud) 

# BackBlaze B2 support for S3-compatible storage

In case you prefer B2, you can use it from your cluster services via Minio.

See the [BackBlaze B2 page](backblaze-b2-s3-storage.md)

# Postgres Database Service

SolaKube supports the deployment of Postgres onto your cluster and simplifies database/user creation for applications needing a database.  

See the [Postgres page for details](postgres.md). 

# Your own application/components deployments

You may create your own SolaKube deployers that does automated deployments for your specific needs from Helm charts and/or plain Kubernetes deployment descriptors. 

Every module has a deployment script subfolder under the **scripts/deploy** folder and optionally a deployment artifact folder under the **deployment** folder. 

For Helm based deployments, see "postgres", for plain Kubernetes descriptors, see the "hetzner" module. Mix between the two are also possible since these are Bash scripts.