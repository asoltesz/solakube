# Docker Registry

SolaKube supports the deployment of the bare-bone Docker Registry released by Docker itself.

This only supports Docker images (no Helm chart support), has no user interface at all and doesn't have full-blown access control. However, it also has modest default resource needs in terms of memory and CPU so it is eminently suitable for small clusters.  

It provides credentials for a single user so cluster administrators can use it in a secure way. For small organizations this may be suitable since only a limited number of people will know the credentials.

This is not ideal for larger organizations where there is a high number of people needing access to the different parts of the registry in a strictly controlled manner. 

# Configuration

The default registry installation allows deleting the images.

## CPU/Memory usage

The default resource usage of the Docker Registry is limited for 256 MB of RAM. 

This is suitable for a couple of concurrent threads pushing/pulling images to/from the registry.

When more is needed, raise the resource allocation in chart-values.yaml.

## Storage space and storage class

The registry will need a fair amount of space, so class preference is changed.

~~~
export REGISTRY_STORAGE_CLASS="hcloud-volumes,openebs-hostpath,rook-ceph-block,standard"
~~~
In smaller clusters, the Rook provider is better used for smaller volumes (for larger ones, Hetzner Cloud Volumes may be more suitable).

Unless specified, the Registry will get 10 GB storage. Depending on how many application images you want to store, you may need to raise it.
~~~ 
export REGISTRY_PVC_SIZE="10Gi"
~~~

## Shared secret (admin password)

The password to be used for the single user of the registry called "admin".
 
~~~
# Password for the 'admin' user of the registry
export REGISTRY_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"
~~~

# Image maintenance

Docker images are fairly large and if you often change image versions you may be left with a lot of image garbage that you don't use anymore but they still occupy storage space in the Registry.

E.g: you use the 'latest' tag on an image coming from a registry that changes often, and your pods get re-scheduled often)

## Deleting the images you don't need

SolaKube deploys the Reg-Tool container by byrnedo in order to allow basic maintenance on the registry.

The "sk registry regtool" sub-command executes in this pod.

~~~
# List all image repos in the registry
sk registry regtool list

# List tags within an image repo (busybox)
sk registry regtool list busybox

# Delete a specific tag from a repo
# (will not remove image layers by itself, see garbage-collection for this) 
sk registry regtool delete busybox latest

~~~

## Executing garbage collection

This will physically delete all image layers that are not referenced by any valid/existing image tags from the registry.
~~~
sk registry garbage-collect
~~~
