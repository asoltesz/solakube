This allows manual testing of cluster creation from you rancher server if the cluster provisioning fails in Rancher.

You should use RKE from your Rancher server to simulate similar network conditions.

Correct the ip addresses according to their IP on the private network you allocate for your cluster (e.g.: 10.0.0.0/16, see: "private_network_subnet")