# Cluster Features

The SolaKube deployed cluster has the following features:

Availability
- A single [Hetzner Floating IP (Fip)](https://wiki.hetzner.de/index.php/CloudServer/en#What_are_floating_IPs_and_how_do_they_work.3F) is used to direct incoming traffic to the cluster. The Fip is always assigned to a cluster node and that node will accept traffic and direct it inside the cluster.
-  The Fip is automatically transferred when node failure is detected by Kubernetes, so if the Fip-holder node crashes the Fip is reassigned to a healthy node and the cluster remains operational and available for external requests. 
- The Nginx Ingress Controller (ingress-nginx) is installed on all of the nodes, so if the Fip transfer happens, the new gateway can immediately start directing traffic without manual intervention and minimal delay.

Node structure/resources
- You can choose any node structure (masters, etcd nodes, workers) and resources (RAM, CPU, storage) you want by declaring every node with an appropriate Hetzner VM type (specifies resources) and cluster roles in the Terraform config before cluster creation.
- Minimal node count is 3 (Kubernetes recommendation)
- The cluster can later be extended with new nodes by defining them in the config and re-executing Terraform.

HTTPS Access
- Cert-Manager gets installed on the cluster which allows easy acquiring of HTTPS/TLS certificates from Let's Encrypt for different services installed on the cluster
- A wildcard certificate may also be used for the cluster (if your DNS provider is supported by cert-manager's dns01 challenges).
- More in [Certificate Management](certificate-management.md) 

Networking
- All cluster nodes are attached to a [Hetzner Network](https://wiki.hetzner.de/index.php/CloudServer/en#Networks) which allows isolated and private communication between the nodes. However the communication is unencrypted.

Storage & persistence
- [Hetzner Volumes (HVol)](https://wiki.hetzner.de/index.php/CloudServer/en#Volumes) are immediately usable for persistence after cluster provisioning, so PVCs get automatically served by allocating them on new Hetzner Volumes.
  - HVols have the minimum size of 10 GB, are extendable and are stored on redundant, HA storage.
- Optionally, [Rook/Ceph](rook.md) can also be used to share the disk space available directly on the Hetzner virtual machines as distributed storage that can be allocated to workloads. The installer script supports setting up a Rook/Ceph storage cluster on the nodes (min. 3 nodes). 
- Databases like PostgreSQL and other workloads requiring persistence can be readily deployed on the new cluster.
- More in [Persistent Volumes](persistent-volumes.md)

[Disaster Recovery](disaster-recovery.md)
- [Velero](velero-backups.md) deployment as the main DR tool
- Default application backup profiles for supported applications

[Postgres-As-A-Service](postgres.md)
- A [simple Postgres deployment](postgres-simple.md) for prototyping, development
- [CrunchyData Postgres Operator](postgres-pgo.md) for deploying highly available, scalable, performant Postgres clusters on your K8s cluster.  

Cluster Management
- The newly provisioned cluster is registered into your Rancher instance, so RBAC, Monitoring, Catalog, Etcd backups and other management features are available for it.

# Applications & further Infrastructure Components

After the cluster is fully provisioned, you can immediately start manually installing applications from Rancher's Catalogs via the Rancher UI or with Helm.

SolaKube also supports the deployment of a small set of [popular applications/components](applications.md) manually or automatically, as part of the cluster deployment process. 

More details on the [Applications & Components page](applications.md).