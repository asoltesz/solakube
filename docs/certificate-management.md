# Certificate Management

SolaKube supports installing Cert-Manager for easy TLS certificate management with Let's Encrypt.

Wildcard (cluster-level, dns01) certificate and per-service (http01) certificates are both supported (even both at the same time).

The LETS_ENCRIPT_ACME_EMAIL [variable](variables.md) is required for all issuers.


# Wildcard DNS record

SolaKube doesn't support automated DNS record management yet (like ExternalDNS), so you either manually maintain your DNS records for each service running on your cluster (that allow traffic to find your cluster) or need to create a wildcard DNS entry/entries.

For example, the *.example.com DNS record may resolve all of your services (that are not specifically covered with a dedicated DNS entry).

Both the wildcard and single-service DNS record(s) should point to the Floating IP of the cluster.

Note: Do not confuse wildcard certificates with wildcard DNS records, DNS records only direct traffic to your cluster, certificates/keyw will make the connection secure (and accepted as secure by browsers).


# Per-service certificates

SolaKube supports getting separate TLS certificates individually for each installed service (say, a dedicated certificate for pgadmin.example.com for a PgAdmin instance installed on your cluster).

In this case, a http01 ClusterIssuer will be installed on your cluster that will be referenced by Certificates that are created individually for the services (one certificate per service).

Set the LETS_ENCRYPT_DEPLOY_PS_CERTS [variable](variables.md) to "Y" if you want to use this certificate mechanism.

A drawback of this method is that you may run out your Let's Encrypt quota (see Let's Encrypts limits), since you need a separate certificate for each externally accessible service. This is especially true for experimentation periods or if you often need to destroy and re-build your cluster from scratch for other reasons.

An advantage of this method that you can easily get certificates from different domains for the services running on the same cluster (say pgadmin.example1.com and wordpress.example2.com).

Also an advantage that with http01 you don't necessarily need to have continuous access to your DNS (a single wildcard DNS record may suit your case). 


# Wildcard certificate (cluster-level, CloudFlare dns01)

SolaKube supports getting a wildcard certificate for your cluster automatically, so that there is no need to request separate certificate for each and every service. All services may use the same wildcard certificate. 

In this case, all services are named to be under the scope of the wildcard certificate. Say, the wildcard certificate is for *.example.com, a service may be accessible on pgadmin.example.com.

Naturally, you can still supply your own certificate for select services if you want to, or use the http01 issuer to get a dedicated certificate for the service.

Currently, only CloudFlare is supported directly for the necessary dns01 challenge. You may patch/modify the descriptors freely for your own DNS provider (it needs to be supported by Cert-Manager as well). Review the relevant Cert-Manager docs to customize the deployment descriptors according to your own DNS provider and see cloudflare-issuer.yaml and cluster-certificate.yaml as examples.

To enable the use of the cluster/wildcard certificate mechanism:
- set the CLUSTER_FQN [variable](variables.md) (e.g.: example.com or cloud.example.com)
- set the LETS_ENCRYPT_DEPLOY_WC_CERT [variable](variables.md) to "Y"

An advantage of this method is that Let's Encrypt limits are much-much harder to exhaust even in the experimentation period. A single certificate is requested when the cluster is provisioned.

NOTE: It is possible to use several wildcard certificates in parallel but SolaKube doesn't have built-in support for it. See the scripts and environment variables how you can manually deal with this.

# Application deployment

When a SolaKube-supported application deployer script runs (e.g.: pgAdmin), it will check if a certificate needs to be deployed at all (or there is a TLS secret supplied independently). 

First, the <SERVICE>_TLS_SECRET_NAME [variable](variables.md) will be checked. If it is specified, the ingress will simply reference that. If not, SolaKube will try to find or create a TLS certificate for the ingress.

If the requested application/service FQN is covered by the CLUSTER_FQN of the wildcard certificate, the already existing wildcard certificate will be used for the service. In this case, an empty TLS secret will be created and Replicator will fill it up with the content of the wildcard certificate (that is residing in the cert-manager namespace)

If CLUSTER_FQN doesn't cover the service FQN, a http01 certificate request will be placed in the namespace of the application, so if the http01 ClusterIssuer was deployed, the TLS will be created automatically. 

# Mixed use

Wildcard/cluster and per-service certificates can both be used in parallel.

The component/application deployer scripts will always check if a service is under the CLUSTER_FQN. If it is, and wildcard certificate management is allowed, the service will not get a dedicated certificate but it will use the wildcard cert instead.

# CloudFlare

Currently, the Cloudflare API key is needed which is a bit too broad permission-wise (if someone gets your CloudFlare API key from the cluster secret, it can cause a lot of damage with it). 

This will need to be changed to API token usage when support for it gets stabilized and documented in Cert-Manager. See [here](https://github.com/jetstack/cert-manager/issues/2036) and [here](https://github.com/jetstack/cert-manager/pull/2170)
