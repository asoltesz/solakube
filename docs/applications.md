# Applications

SolaKube supports the automated deployment for a limited set of applications.

Manually, you can deploy applications with the Rancher UI (from its catalogs) or with Helm.

# Postgres

A simple, one-node Postgres installation with the Bitnami images can be done with the "postgres" deployer module. This can be extended for your needs but it is meant to be as an entry-level solution.

Via the SolaKube deployer, you typically combine it with Hetzner Cloud Volumes or the Rook storage cluster so you should get a minimally acceptable fault tolerance since the DB itself is stored on distributed/HA storage and the Postgres pod itself gets rescheduled if the node fails under it.

With this solution, you need to roll your own backup/restore strategy.

For a higher-grade Postgres setup, you need to use a full-blown Kubernetes Postgres Operator, like that of [CrunchyData](https://github.com/CrunchyData/postgres-operator) or [Zalando](https://github.com/zalando/postgres-operator). These all support streaming replication with failover, full/incremental backups, restores, multi-cluster DB user management...etc.

The deployment of the CrunchyData Operator is planned to be integrated into SolaKube, since it has Ansible support and preliminary tests were successful with it. You may track its progress on [issue #11](https://github.com/asoltesz/hetzner-k8s-builder/issues/11).

# pgAdmin

Whichever Postgres DBMS setup you implement, you will probably need to have a web administrative interface for your DBs. 

The "pgadmin" deploy module deploys pgAdmin4 on your cluster.

Note: Your Postgres DBMS deployments are typically visible on a ClusterIP within the cluster. Check them on the Rancher UI or with kubectl.   

# Your own application/components deployments

You may create your own SolaKube deployers that does automated deployments for your specific needs from Helm charts and/or plain Kubernetes deployment descriptors. 

Every module has a deployment script subfolder under the **scripts/deploy** folder and optionally a deployment artifact folder under the **deployment** folder. 

For Helm based deployments, see "postgres", for plain Kubernetes descriptors, see the "hetzner" module. Mix between the two are also possible since these are Bash scripts.