# Mailu (Mail Services)

[Mailu](https://mailu.io) is an open-source project for providing email services for organizations.

- Accepting and storing emails for a mail domain (e.g.: a company domain)
- Webmail (Roundcube) and IMAP access to the emails
- SMTP service for sending emails from within the Kubernetes cluster and from outside email clients (authenticated)
- ...etc other emailing features


# SolaKube installation model

SolaKube allows installing Mailu on the cluster in the following way:

- Postgres databases are automatically created for the Mailu admin service and the Roundcube webmail (the ["pgs"](postgres-simple.md) or the ["pgo"](postgres-pgo.md) Postgres service needs to be installed on the cluster beforehand)
- A [custom Helm chart](#Helm chart) is used for installation
- [Automatic DNS record maintenance](#DNS Record Maintenance) for your mail services


# Configuration

## SolaKube SMTP settings when Mailu is used

When Mailu is deployed on your cluster, you may want to use its SMTP service for sending emails to the outside world (from your applications).

In this case, configure the SMTP_xxx parameters according to your Mailu installation so that all services will get the proper SMTP access parameters.

NOTE: SMTP email sending will not be available for any of the services until Mailu gets deployed.

## DNS Record Maintenance 

In order to allow other mail servers send emails to Mailu-managed email domains, you need to have an MX record and a corresponding A record created in your DNS record registry for every email domain.

NOTE: This cannot be handled with a wildcard certificate and wildcard DNS entry which is generally an option for directing traffic to http(s)/ingress based workloads.

### Automatic DNS record

If you have a domain is hosted at a compatible DNS service provider (e.g.: Cloudflare), SolaKube can automatically create an "A"-type DNS record that points to the Kubernetes host/node running the Mailu Front pod (also responsible for accepting incoming mail before relaying them internally).

SolaKube deploys External-DNS and a specially annotated (dummy) Kubernetes service that makes it possible for Ext-DNS to create the record.

When the Mailu Front pod is re-scheduled to another Kubernetes host, the "A" record will be maintained.

The default setup is configured for CloudFlare. See the [chart-values-extdns.yaml](../deployment/mailu/chart-values-extdns.yaml) file for re-configuring it for your own provider. 

The default setup expects your CloudFlare credentials (in variables.sh):

~~~
export CLOUDFLARE_EMAIL="${SK_ADMIN_EMAIL}"

# The Cloudflare administrator account API key (dns01 issuer)
export CLOUDFLARE_API_KEY="xxx...xxx"
~~~

These will be deployed in a secret for External-DNS to allow dynamic reconfiguration of the "A" record.

The "MX" record has to be manually created and pointed to the "A" record that will be created/maintained by External-DNS.  


### Manual DNS record

This is generally not recommended because it may leave your mail services interrupted when the Kubernetes node running the Mailu Front service pod fails. 

The Front pod itself will be automatically re-scheduled to another node but the "A" DNS record will point to the wrong IP address, until you manually fix them.

In case you do this anyway, make sure that you are notified very quickly about node failures and you have the ability to quickly fix the DNS record.

## TLS certificate management

While Mailu has its own certificate management (via Cert-Manager like SolaKube), the default installation method for Mailu (by SolaKube) is "cert", which means that Mailu will expect the certificates to be provided for it (and it will not try to request the certificates by itself).

The SolaKube deployer will automatically submit a separate certificate request when necessary (cluster-level wildcard cert is not suitable) and replicate the certificate with the name expected by Mailu.

## Ingress-management

SolaKube will automatically replace the ingress deployed by Mailu-Helm chart with its own in order to have a consistent ingress deployed (TLS).

Thus, the Mailu Admin user interface and the webmail will be accessible via an ingress deployed by SolaKube. If you need to customize it, modify the "[ingress.yaml](../deployment/mailu/ingress.yaml)" file.     

## Persistence

Mailu keeps all of its data on a single, shared persistent volume.

This somewhat limits the deployability of Mailu, since Hetzner Cloud Volumes do not have the necessary access mode support for this kind of storage behaviour (ReadWriteMany).

Thus, SolaKube deploys Mailu with a PVC that only requests the ReadWriteOnce access mode. Since Kubernetes only requires that all pods accessing the ReadWriteOnce volume must be on the same node, this provides the opportunity to deploy Mailu, even though in a somewhat limited way.

With Hetzner Cloud Volumes, this limits the Mailu installation by deploying all of the pods onto a single Kubernetes host (hcloud-volumes can only be bound to one host at any given time).

From my limited testing, Kubernetes and the hcloud CSI plugin automatically manage to schedule all of the pods to the same node so no special action is taken to force all of the Mailu pods to the same node.  

In case you need better enforcement, patch the deployments with [pod-related node-affinity rules](https://docs.okd.io/latest/nodes/scheduling/nodes-scheduler-pod-affinity.html)

## Backup (disaster recovery)

SolaKube will automatically deploy a Velero-based backup profile for the Mailu persistent volume.

# Deployment

TODO: TBW

# Accessing Mailu services after installation

## Admin UI 

For creating mail domains, aliases, setting quotas ...etc

~~~
https://mailu.andromeda.example.com/admin 
~~~

## Webmail (RoundCube) 

For testing email sending, forwarding and receiving.

~~~
https://mailu.andromeda.example.com/
~~~
(The root)

# Notes

## Helm chart

For Mailu installation, SolaKube uses a [custom, forked Helm chart](https://github.com/asoltesz/mailu-helm-charts) because the original/official Helm chart has many small deficiencies ATM and merging changes/fixes is very slow on the part of the maintainers (All modifications have been sent as PRs, most of them seem to be simply ignored ATM).