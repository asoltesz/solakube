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

The registry will need a fair amount of space, so class preference can be changed by a parameter like this:

~~~
export REGISTRY_STORAGE_CLASS="hcloud-volumes,openebs-hostpath,rook-ceph-block,standard"
~~~

In smaller clusters, the Rook provider is better used for smaller volumes (for larger ones, Hetzner Cloud Volumes may be more suitable).

If not specified, the DEFAULT_STORAGE_CLASS will be used to select the first available storage class.

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

# Accessing the registry

## Normal, publicly accessible cluster

The registry will be exposed with a normal ingress on HTTPS (by the SolaKube deployer).

The registry does not have a UI but the REST interface will be accessible for pushing and pulling images:
~~~
https://registry.example.com
~~~

The access port is not 5000 but the normal HTTPS port (443).

Pushing and pulling images can both happen via the above URL. The URL can also be utilized as the private registry URL (see below) since the Docker clients on your nodes will be able to resolve the hostname, thus access the registry. 

## Minikube

In non-public test environments, one needs to port-forward the registry to localhost, and push the necessary images via the localhost port.

This can be used to push the image into the repo to test that it is working.

However, it cannot be used for deployments because the docker client in Minikube will not be able to resolve.

Example:

~~~
export POD_NAME=$(kubectl get pods --namespace registry -l "app=docker-registry,release=registry" -o jsonpath="{.items[0].metadata.name}")

kubectl -n registry port-forward $POD_NAME 5000:5000

docker tag my-awesome-image:tag localhost:5000/my-awesome-image:tag
docker login localhost:5000
...log in ...
docker push localhost:5000/my-awesome-image:tag
~~~ 


# Using it as the private registry for the cluster

Define the access parameters into the DEFAULT_PRIVATE_REGISTRY_XX parameters.

See the [Registries](registries.md) for more info on this.

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
