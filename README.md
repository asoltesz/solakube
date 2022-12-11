# SolaKube Kubernetes cluster builder on Hetzner Cloud 

This project aims to simplify the creation of K8s clusters on Hetzner Cloud with Terraform, Ansible and Rancher 

Partially based on Vito Botta's Ansible and Terraform plugins and his article: [From zero to Kubernetes in Hetzner Cloud with Terraform, Ansible and Rancher](https://vitobotta.com/2019/10/14/kubernetes-hetzner-cloud-terraform-ansible-rancher/). It also adds example values, documentation, bugfixes, more reproducibility and further automation on top of it. [Differences with the original article](docs/differences-original-article.md).

For the sake of compactness, the project is referenced as SolaKube.

# Work In Progress
 
WARNING: This is a work in progress and shared only in the hope that it may come useful for others. See the [Issues](https://github.com/asoltesz/hetzner-k8s-builder/issues). Until it reaches 1.0, major structural changes may be introduced.

The configuration describe my personal test cloud (named "andromeda"). If you want to use it as a starting point, please read Vito's article and customize everything according to your own preferences, tokens...etc.

# Cluster features

The SolaKube deployed cluster will have the following features, in short:
- Highly available via Hetzner Floating IP and Nginx-Ingress
- Flexible cluster node structuring and roles
- Automatic HTTPS certificates (per-service or wildcard) via [Let's Encrypt](docs/certificate-management.md) 
- [Data persistence](docs/persistent-volumes.md) (Hetzner Volumes + [Rook/Ceph](docs/rook.md))
- Fully automated, reproducible cluster builds with infrastructure component + application deployments
- Built in [disaster recovery](docs/disaster-recovery.md) tooling (Velero + application backup profiles)
- [Monitoring & Alerting](docs/monitoring.md) via Prometheus or New Relic.
- Simplified deployments for
  - infrastructure components (e.g.: [Postgres as a service](docs/postgres.md), [Velero](docs/velero-backups.md))
  - popular applications ([Nextcloud](docs/nextcloud.md), [Redmine](docs/redmine.md), Wordpress...etc)
  - developer tools (e.g.: [Gitea](docs/gitea.md), [Jenkins](docs/jenkins.md))

For feature details, see the [Features page](docs/features.md)

For details about the directly supported infrastructure components & applications, see the [Applications & Components page](docs/applications.md)

# Requirements, Dependencies
 
Before using SolaKube, you need to ensure that all necessary software is present that are needed for the cluster building processes (Ansible, Terraform, Helm...etc).

See the [Requirements & Dependencies page](docs/dependencies.md) for details.

# Creating and provisioning the cluster

See the [Cluster Creation and Provisioning page](docs/create-provision-cluster.md) about creating the cluster and installing all basic infrastructural elements
