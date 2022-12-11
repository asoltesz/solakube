# S3 storage for Rancher Server and Terraform state 

By default, no S3 storage is used either for the Terraform state or the generated K8s cloud's etcd backup. 

Terraform uses local disk state storage (S3 backend parameters simply commented out, so reverts to default, local disk storage)

Generated K8s cluster doesn't have its etcd backed up.

This is acceptable for a test cloud (no need to pay for S3 storage yet.) but for  production systems, these will be needed.

# S3 storage for cluster services (backup)

The newly generated cluster may use the BackBlaze B2 as an S3-compatible storage.

See the [BackBlaze B2 as S3 storage page](backblaze-b2-s3-storage.md). 

# Other S3 storage providers

Wasabe looks to be a relatively cost-effecive, yet reliable S3 storage provider. It has a 1000 GB minimum storage fee so with modest storage requirements it costs more than it would be necessary.

