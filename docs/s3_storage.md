# S3 storage

By default, no S3 storage is used either for the Terraform state or the generated K8s cloud's etcd backup. 

Terraform uses local disk state storage (S3 backend parameters simply commented out, so reverts to default, local disk storage)

Generated K8s cluster doesn't have its etcd backed up.

This is acceptable for a test cloud (no need to pay for S3 storage yet.) but for  production systems, these will be needed.

# S3 storage providers

Wasabe looks to be a cost-effecive, yet reliable S3 storage provider.
