# Variables and their documentation
 
All variables are explained here that can be used in the deployment.

Most of the scripts expect these as shell variables pre-defined before the script is executed. Missing variables typically result in an input validation failure so the script doesn't even start. 

## Where/how to define them 

One way to store them in the shell-configuration shell script belonging to the cloud (for example configure-andromeda.sh) This file is under version control, so only do this if the private information stored in  the variables can be checked into the Git repo you intend to store your changes in.

An other way is to define these variables in the Terraform "secret" definer shell script that is placed in ~/.secrets and named according to the cluster name (e.g.: ~/.secrets/terraform-andromeda.sh). Before starting a SolaKube script (that requires one or more of the variables), the script can be loaded directly or via configure-andromeda.sh (e.g. with the command "source ../../configure-shell.sh" when being in the hetzner deployment subfolder). The .secrets folder is not intended to be under version control.

The variables need to be defined with Bash export statements so they become visible as shell variables (e.g.: export HETZNER_API_TOKEN=dkljfsldkjf) after the script is sourced into the shell you work from.

There is a sample variables file in the templates folder that can be used as a starting point. 

# Common variables

## RANCHER_API_TOKEN

The Rancher API token that Terraform will use to create/modify the cluster in Rancher. 

## RANCHER_HOST

The FQN of your Rancher server (e.g.: rancher.example.com). 

The Rancher API v3 must be available on this host, with https.

## RANCHER_CLUSTER_ID

The id of the cluster in rancher in the form of "c-s6sds". 

This is printed by the apply-cluster.sh script after Terraform is finished as part of the cluster URL. Copy it out from the URL (the last part of it after the backslash) and define it in this variable.

## HETZNER_CLOUD_TOKEN

The Hetzner Cloud API token that can be used by Terraform to create the Virtual Machines that will form the Kubernetes cluster nodes.

It will also be stored in a secret in the newly created cluster in order to allow Hetzner Cloud specific features work:
- Floating IP reassignment in case of a node failure
- Creating cloud Volumes to satisfy Persistent Volume Claims for deployed applications that need persistence

## HETZNER_FLOATING_IP

The Floating IP address creted for the cluster so that deployed services become accessible from the outside world.

This IP may to be registered in your DNS domain either with a wildcard domain entry (like *.example.com).

If you don't want to use a wildcard dommain entry, you will need to register a DNS entry with this IP for every service you want to be accessible (say, pgadmin.example.com)    

# HTTPS / TLS certificate management (cert-manager)

export LETS_ENCRYPT_ACME_EMAIL=asoltesz@nostran.com


## CLUSTER_FQN

The fully qualified domain name of tha cluster. 

If defined, and a service doesn't have a dedicated FQN defined for it, the service FQNs will be inferred from the CLUSTER_FQN.

Example 1: 
CLUSTER_FQN: andromeda.example.com
PGADMIN_FQN (inferred): pgadmin.andromeda.example.com

Example 1: 
CLUSTER_FQN: example.com
PGADMIN_FQN (inferred): pgadmin.example.com

## LETS_ENCRYPT_DEPLOY_WC_CERT

Whether the installer should deploy the Cert-Manager dns01 issuer (currently we support CLoudFlare only) and request a wildcard certificate for the cluster.

This is only possible if the CLUSTER_FQN is set to a domain.

If a wildcard certificate is available for the cluster, SolaKube can check if a service FQN is covered under the wildcard certificate and if so, it doesn't create a separate certificate request for it.

See also: [Certificate Management](certificate-management.md)

## CLUSTER_CERT_SECRET_NAME

The name of the secret for the cluster-level, wildcard certificate.

If the FQN of a service is under the CLUSTER_FQN (or derived from it), this TLS secret will be set to the ingress of the service so that the HTTPS service will serve the shared wildcard certificate.

This can be set even if the user deploys its own, manually crafted wildcard certificate independently from SolaKube.

If SolaKube auomatically creates the wildcard certificate for the cluster, this secret name will be used for storing the TLS cert and private key.
 
 See also: [Certificate Management](certificate-management.md)
 
 ## LETS_ENCRYPT_DEPLOY_PS_CERTS
 
 Whether the installer should deploy the support for per-service certificates.
 e.g.: a http01 ClusterIssuer
 
 If this is set to Y and a service doesn't have a pre-created TLS cert supplied for it, the installer scripts will check if the wildcard cert is enabled and covers the service FQN. If it doesn't cover or not enabled, SolaKube installers will try to install a http01 certificate request for the service.
 
 See also: [Certificate Management](certificate-management.md)

## CLOUDFLARE_EMAIL

The Cloudflare administrator account email address.

Used together with CLOUDFLARE_API_KEY.

Only needed when a wildcard/cluster TLS certificate needs to be automatically created.

## CLOUDFLARE_API_KEY

The Cloudflare administrator account API key

Do not confuse it with CloudFlare API tokens, SolaKube (cert-manager) doesn't support those (yet).

Only needed when a wildcard/cluster TLS certificate needs to be automatically created.

## <SERVICE>_TLS_SECRET_NAME

This variable tells the deployer scripts if there is an independently provided TLS secret for the service ingress to be used.

If not set, SolaKube will try to find or create a TLS secret for the ingress and that will be referenced.

If set, the ingress will reference the specified TLS secret.

# Application/Service deployment

Variables that are typically used during the deployment of an application/service on the cluster.

## <SERVICE>_STORAGE_CLASS

The storage class to be used for a service/application when that requests storage via a Persistent Volume Claim.

For example: POSTGRES_STORAGE_CLASS=rook-ceph-block

See [Persistent Volumes](persistent-volumes.md) for details.

## <SERVICE>_APP_NAME

The name of the application instance to be deployed for a certain application/service type.

For example: POSTGRES_APP_NAME=postgres

This will be the name of the namespace into which the service is deployed.

If the application is deployed with Helm, the name of the release will be this.

