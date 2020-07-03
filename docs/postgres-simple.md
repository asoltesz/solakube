# Postgres (simple version)

A simple, one-node Postgres installation with the Bitnami images can be done with this ("postgres-simple") deployer module. This can be extended for your needs but it is meant to be as an entry-level solution.

Via the SolaKube deployer, you typically combine it with Hetzner Cloud Volumes or the Rook storage cluster so you should get a minimally acceptable fault tolerance since the DB itself is stored on distributed/HA storage and the Postgres pod itself gets rescheduled if the node fails under it.

With this solution, you need to roll your own backup/restore strategy.

# Configuration

## POSTGRES_STORAGE_CLASS

The storage class for the database files (PVC).

Optional, defaults to the first available storage class listed in DEFAULT_STORAGE_CLASS.

# Deploying

## With the initial cluster build

By setting this in variables.sh:

~~~
export SK_DEPLOY_POSTGRES_SIMPLE="Y"
~~~

## Manually, after the initial cluster build

By executing the deploy command:

~~~
sk deploy postgres-simple
~~~

# Using Postgres databases by other deployments/applications

The Postgres access parameters - which are used by other deployers like Nextcloud - will automatically be configured for you:

- POSTGRES_ADMIN_USERNAME
- POSTGRES_ADMIN_PASSWORD
- POSTGRES_SERVICE_HOST

See their docs and defaults in variables.sh.
 
