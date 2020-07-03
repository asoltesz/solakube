# Postgres Database Service

Many applications need a database for the storage of their relational data (like.: NextCloud, Gitlab...etc).

SolaKube supports the deployment of Postgres on your cluster as a service and the deployers of applications that need a database automatically create an appropriate database and user for the application in the Postgres service.  

# Postgres (simple version)

A simple, one-node Postgres installation with the Bitnami images can be done with the "postgres-simple" deployer module. This can be extended for your needs but it is meant to be as an entry-level solution with limitations.

See the [Postgres-Simple deployer page](postgres-simple.md). 


# Postgres with CrunchyData Postgres Operator

For a production-grade Postgres setup, SolaKube supports the simplified deployment of the [CrunchyData Postgres Operator](https://github.com/CrunchyData/postgres-operator) 

The operator supports streaming replication with proper fail-over, full/incremental backups, point-in-time recovery, multi-cluster DB user management...etc.

See the details in the [CrunchyData Postgres Operator](postgres-crunchy.md) page. 


# pgAdmin

Whichever Postgres DBMS setup you implement, you will probably need to have a web administrative interface for your DBs. 

The "pgadmin" deploy module deploys pgAdmin4 on your cluster.

Note: Your Postgres DBMS deployments are typically visible on a ClusterIP within the cluster. Check them on the Rancher UI or with kubectl.