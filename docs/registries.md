# Docker Registry & Helm Repository

# Docker registries (internal/external, public/private)

In most non-trivial, production-grade Kubernetes clusters there is a private Docker registry that allows for higher self-containment, better resiliency to external changes and faster Docker image pulls compared to pulling images from external registries.

If the cluster contains internally developed applications, it is often a requirement that the Docker images of the application are NOT published in public registries like Docker HUB but only in some private registry.

In a lot of organizations the production environments are firewalled (air-gapped) from the internet and the cluster doesn't have access to external Docker registries. This requires that you have a private registry inside the internal network of the organization. 

If the private registry is part of the cluster (an internal registry), that makes the cluster more self-contained and resilient. Also, it becomes possible to better calculate the load on the registry, if it is not shared among several clusters. (A drawback may be some extra resource consumption for storage and CPU for operations like vulnerability scans)

In case of a cluster-internal registry you push all Docker images (used by the cluster) into the internal registry and the images are distributed among the nodes from there. In case your cluster is dynamic and workloads get rescheduled between nodes often, image pulls will be much faster from the internal registry than from external sources.

Even if the original binaries and sources of the application are lost and the container is removed from its original distribution registry (Docker HUB), your cluster can still operate without issues with an internal registry. This may not happen often but it DOES appen from time-to-time and it is impossible to solve without a private registry.  

Internal registries may be cleaned and pruned very efficiently because you may only need to keep those docker images that have active deployments (using delays, allowing for quick rollbacks after deployment of buggy deployments)

The content of an internal registry is usually backed up like any other persistent data on your cluster, so you can migrate all of your Docker images together with your normal data and recreate your cluster practically anywhere.

# Helm repositories

Helm repositories are similar to Docker registries in purpose, only they contain Helm charts instead of Docker images.

Helm charts are needed only when you first install or update an application, as opposed to Docker images which are needed any time a workload is (re)scheduled on a cluster node.

Helm charts may also be managed in private Git repositories and charts downloaded to the deployer machine when needed. Not as elegant as a full-blown Helm chart registry but workable.   

Due to this, having a private Helm registry is less important than an internal Docker registry.

# Docker Registry (simple)

SolaKube supports the deployment of the bare-bone Docker Registry released by Docker itself.

This only supports Docker images (no Helm chart support), has no user interface at all and doesn't have full-blown access control. However, it also has modest default resource needs in terms of memory and CPU so it is eminently suitable for small clusters.  

Details in the [Docker Registry](docker-registry.md) page.

# JFrog Container Registry (JCR)

This is a full blown Docker image and Helm chart registry with proper access control (e.g.: LDAP authentication). However, its resource use is much-much higher. Doesn't have built-in vulnerability scanning, requires a paid component (XRay) for it.

As of version 7.6.3, JCR requires a minimum of 1,5 GB of RAM to be allocated (default Helm chart install, no tuning) even for starting up. The official recommendation for their "small" system scenario is minimum 4 GB of RAM. This is not ideal for smaller clusters (IOT, enthusiasts...etc). 

SolaKube provides a deployer (jcr) for this registry but this should be considered alpha level as of now. 

Some of the issues:

- resource requests/limits need to be configured manually
- memory usage may be possible to reduce, since this is a Java application and by default, the Helm chart does not seem to provide it with any proper heap settings

WARNING: Future SolaKube efforts will probably center on Harbor. 

# Notes on other registries

## Harbor

Full blown Docker/Helm registry like JCR but fully open-source and managed by the CNCF.

Has LDAP integration and vulnerability scanning.

It seems to require as much resources as JCR but this should still be preferred over JCR due to its OSS nature, feature set and activity around it.

NOTE: In SolaKube this seems to make more sense than JCR.

## Portus

Exclusively a Docker image registry but has LDAP integration and built-in vulnerability scanning.

Looks to require much less resources than Harbor/JCR/Nexus. Default beta Helm chart values recommend ~ 2GB of RAM (adding up all components). 

Currently, it doesn't have a stable Helm chart. There used to be a beta chart in incubator but it has been removed. It seems to have very little activity around it.

## Nexus OSS


