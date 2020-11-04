# Test services with K3S

Some of the functionality can be tested on a single-node or multi-node K3S server, which is a lightweight Kubernetes implementation by Rancher.

# Install K3s on your host

Use public docs for installing a single/multi-node K3S cluster.

# Start the K3S server node

Make sure you provide the external IP address of the node(s), otherwise, it will not be included in the "addresses" of the node and External-DNS may not be able to utilize them.

~~~
k3s server -node-external-ip 135.181.45.119
~~~