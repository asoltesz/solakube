# Monitoring & Alerting

Cluster monitoring and alerting is important for every production Kubernetes cluster.

# New Relic One

New Relic One is cloud based monitoring & alerting solution that has a free layer (ATM, 100 GB ingested data per month). This is suitable for small Kubernetes clusters.

Since the monitoring UI and the alerting system is external to the cluster, these services do not consume any CPU or RAM resources in your cluster (as opposed to an in-cluster Prometheus instance). Only the data collector pods (one per K8s host) consume processor and CPU. 

It also doesn't require internal storage space for historic data retention. 

You can install the New Relic monitoring client into your cluster with the "newrelic" deployer:

~~~
sk deploy newrelic
~~~ 

or by setting the SK_DEPLOY_NEWRELIC variable to "Y" before the initial cluster provisioning.

NOTE: You will need to register a free account with New Relic and put the license key into variables.sh (see the variables.sh template). 


# Prometheus (in-cluster)

Prometheus can be installed into the cluster and should provide detailed information about the nodes and workloads.

You can activate monitoring after the successful SolaKube deployment on the Rancher user interface which will install all of the necessary components.

You can also install Prometheus in an automated way by setting the following variables in terraform.tfvars:

~~~
enable_cluster_monitoring = true
enable_cluster_alerting = true
~~~  

WARNING: Prometheus consumes a fair amount of resources. See below.

## Prometheus resources

See the rancher docs for the resources.

https://rancher.com/docs/rancher/v2.x/en/monitoring-alerting/v2.0.x-v2.4.x/cluster-monitoring/#resource-consumption-of-prometheus-pods

The page is inconsistent at the moment (two tables with conflicting resource usages)

Taking the more optimistic values in the page, nd calculating with a small, 3-worker-node cluster you will need to reserve :
- 90 MB of RAM for the node exporter pods (30 MB ech node)
- 130 MB of RAM for the kube-state exporter pod
- 1500 MB for the Prometheus core/backend pod set
- 100 MB for the Prometheus Operator
- 150 MB for Grafana (the UI)

NOTE: If you have a small cluster, you may be better off with the New Relic free layer (see above)

You can customize some of these values by forking & modifying the "rancher" terraform module and modifying the values in its main.tf:

~~~
  cluster_monitoring_input {
    answers = {
      "exporter-kubelets.https"                   = true
      "exporter-node.enabled"                     = true
      "exporter-node.ports.metrics.port"          = 9796
      "exporter-node.resources.limits.cpu"        = "200m"
      "exporter-node.resources.limits.memory"     = "200Mi"
      "grafana.persistence.enabled"               = false
      "operator.resources.limits.memory"          = "500Mi"
      "prometheus.persistence.enabled"            = false
      "prometheus.persistent.useReleaseName"      = "true"
      "prometheus.resources.core.limits.cpu"      = "500m",
      "prometheus.resources.core.limits.memory"   = "750Mi"
      "prometheus.resources.core.requests.cpu"    = "150m"
      "prometheus.resources.core.requests.memory" = "250Mi"
      "prometheus.retention"                      = "12h"
    }
  }
~~~

NOTE: RKE may allow further customizations but the Rancher/RKE Terraform module only handles those above (see their docs for further possible customizations).
