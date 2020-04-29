# Minikube

Certain functions of SolaKube can be tested with MiniKube so that no real cluster needs to be created for testing/development of deployers...etc.

This makes development/testing work more efficient since only reasonably well working deployer needs to be tested on a real cluster.

# Create the cluster

~~~
minikube start --kubernetes-version=v1.15.11
~~~

# Setup ingresses with Minikube

Guide: https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

## Install Ingress Controller capability

~~~
minikube addons enable ingress
minikube addons enable ingress-dns
~~~

## Ensure services get resolved

In order to be able to browse the services on your local minikube instance similarly to a public cluster on the internet (e.g.: pgadmin.example.com) you either need to maintain  the service hostnames in your /etc/hosts file, or configure/use ingress-dns.

## Configure ingress-dns

See confguration in the [Minikube Ingress DNS docs](https://github.com/kubernetes/minikube/tree/master/deploy/addons/ingress-dns). 

## Add the Minikube host to your /etc/hosts

Use this to find out the IP address of the Minikube VM
~~~
minikube ip
~~~

Add the IP address for each service to the /etc/hosts of your machine
~~~
sudo echo "192.168.39.48 nextcloud.andromeda.mk" >> /etc/hosts
sudo echo "192.168.39.48 pgadmin.andromeda.mk" >> /etc/hosts
~~~

IMPORTANT: Unfortunately, sometimes minikube changes its IP address and currently doesn't provide any options to have a predictable IP address. When the IP address changes, you need to edit your /etc/hosts file and replace the old IP address with the new ones. 

# Viewing objects on the dashboard

~~~
minikube dashboard
~~~

# Configure .variables.sh

Set the "minikube" cluster type to instruct variables.sh for special actions.

~~~
# The type of cluster we work with
# Only needs to be set in case we work with minikube for local testing
SK_CLUSTER_TYPE="minikube"
~~~

This should result in an automatic reconfiguration of the Cluster FQN to andromeda.mk (see the variables.sh template)


# Typical operations around SolaKube

TBW