# Hetzner-Cloud support components

This module of SolaKube deploys the components necessary to integrate your k8s cluster with Hetzner Cloud infrastructure.

# Manual deployment

This is normally a non-optional part of the cluster build process.

Use the "sk deploy hetzner" command to manually deploy the necessary components.


# Verifying the installation

- all deployments must be Active in the "fip-controller" namespace.
- hcloud-controller-manager should be active in kube-system
- hcloud-csi-controller should be active in kube-system
- hcloud-csi-node should be active in kube-system (1 pod on each node)

# Testing Floating IP reassignment

You can test if the Hetzner Floating IP is properly, automatically reassigned to another cluster node when you switch off the server that is currently holding it.

Execution:
- On the Hetzner Cloud Console, check which node is holding the Floating IP.
- Power down the server/node
- The Floating IP should be reassigned to another node
- Your workloads should be available after the reassignment is done

Caveats:
- If the fip-controller is unevenly distributed (see issue #5), floating IP handover may be slower (even a minute)
- Normally, handover should happen within 10 seconds

# Testing the Cloud Volume allocator (CSI) plugin

In Rancher, set the default storage class to hcloud-volumes (normally, it should be the default).

Install any application requiring persistent storage (from the Rancher catalog, on the UI).

Check if a volume has been successfully allocated (in Rancher UI) and your application works. 