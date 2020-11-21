# BackBlaze B2 as S3 storage

The "b2s3" deployer module of SolaKube can deploy [Minio](https://min.io) in B2 gateway mode so that cluster services (and potentially external services) can use your B2 account for storage via the S3 protocol.

NOTE: This storage is not to be confused with Hetzner Cloud Volumes and Rook distributed storage since it is way-way slower and cannot be used to create/bind Persistent Volumes from it.  

NOTE-2: It is now possible to use B2 via a more "native" S3 interface. In this case you don't need B2S3 (Minio) and you configure it as normal S3 storage. As of 2020-MAY-11, this is in beta, so I would recommend waiting for a couple of months for it to stabilize. 


# Why B2 

Some of the components on the cluster (e.g.: backups) require S3 storage in production.

For smaller clusters and workloads, these backup needs are modest (10 - 100 GB).

Also, some applications where access speed can be lower (e.g.: a Nextcloud file backend) can also profit from cost-effective, remote storage.

The most cost-effective provider in this storage requirement range is currently BackBlaze B2 (Wasabi has a minimum storage limit of 1000 GB). They have a 10 GB free layer and you can extend that easily to any storage size.

# How 

BackBlaze B2 doesn't have native S3 interface so it requires a gateway for all clients that can use the Amazon S3 protocol but cannot use the BackBlaze B2 protocol (S3 is far more popular ATM).

The b2s3 module installs the MinIO S3 in B2 gatewa mode. This requires comparatively little resources (default installation: 2 pods, 64 MB RAM required each).
   
# Configuration variables (variables.sh)

For a successful deployment, you need to create a BackBlaze B2 account, create an application key and define it for SolaKube.
 
## B2_ACCESS_KEY

The access/application key that you created for the cluster in your B2 account. 

## B2_SECRET_KEY

The secret key/token belonging to the access key. 

# Deployment to the cluster

For including the deployment in the initial cluster buuilding process, set the **SK_DEPLOY_B2S3** variable to "Y" in **variables.sh**.

To deploy it manually afterwards:

~~~
sk deploy b2s3
~~~

To remove it:

~~~
sk undeploy b2s3
~~~


# Checking the B2 files/buckets via the Minio UI

An ingress is deployed for te Minio service, so - by default - you can view your B2 files on a URL like this

~~~
http://b2s3.example.com
~~~

Assuming your cluster FQN is example.com.

# Using the S3 gateway from within the cluster

Minio becomes accessible on a ClusterIP via http.

The Minio S3 service becomes available on an internal hostname within the Kubernetes cluster (b2s3.b2s3.svc.cluster.local) on port 9000 over HTTP.


Port 9000 can be used to access the service in the cluster IP. 

# Using B2 with Minio for Rancher Server and Terraform

Due to the fact that the B2/S3 protocol translation gets installed on the cluster you are provisioning, this B2S3 solution is less suitable for the Rancher Server's etcd backup and Terraform's state storage (you destroy the cluster, you loose the S3 storage as well).

However, you can install a similar solution on your Rancher Server manually and that would be independent of the cluster.

Use publicly available guides for this but a very simple, pure Docker based solution is as follows:

~~~
docker run \
  --name minio-b2-gateway \
  --env "MINIO_ACCESS_KEY=xxxxxxxxx" \
  --env "MINIO_SECRET_KEY=xxxxxxxxx" \
  --publish 9000:9000 \
  --restart unless-stopped
  minio/minio gateway b2
~~~ 

This starts the gateway in a Docker container, exposes the 9000 port and ensures that the service restarts automatically, unless you manually stop it (e.g.: after a server restart).
