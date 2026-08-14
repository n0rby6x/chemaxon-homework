# Exercise 2 - S3 backup bucket

An S3 bucket configured to store filesystem backups for **exactly 180 days**
(configurable), with a cross-account IAM role (`backup_uploader`) allowed to
upload into it.

## What's implemented and why

| Feature | Why |
|---|---|
| **Lifecycle rule - expire after `retention_days` (180)** | Directly implements "180 days and no more". Also expires noncurrent versions after 30 days and aborts incomplete multipart uploads after 7 days, to avoid paying for storage that serves no purpose. |
| **Versioning enabled** | Required prerequisite for Object Lock; also protects against accidental overwrite of a backup with the same key. |
| **Object Lock, COMPLIANCE mode, `retention_days`** | Backups can't be deleted or overwritten - not even by the account root - before the retention period elapses. This is the standard "immutable backup" pattern and protects against ransomware/accidental/malicious deletion. Combined with the lifecycle rule above, backups are both protected *during* the 180 days and guaranteed to be gone *after* them. |
| **Server-side encryption (default SSE-S3, optional SSE-KMS via `use_kms`)** | Encrypts data at rest. SSE-S3 is free; flipping `use_kms = true` swaps in a customer-managed KMS key with rotation enabled, for extra control/audit trail (CloudTrail key usage logs) at a small extra cost. |
| **Public access block (all 4 settings) + Bucket owner enforced (no ACLs)** | Removes an entire class of misconfiguration risk (accidentally-public buckets/objects). |
| **Bucket policy: least-privilege grant to `backup_uploader`** | Only `PutObject`, `PutObjectRetention`, `GetObject`, `ListBucket` are granted - no delete, no bucket administration. |
| **Bucket policy: deny insecure transport (`aws:SecureTransport=false`)** | Blocks any plain-HTTP access to the bucket. |
| **Bucket policy: deny unencrypted uploads** | Belt-and-braces on top of default bucket encryption - any `PutObject` that doesn't declare the expected `x-amz-server-side-encryption` header is denied. |

## Usage

```bash
cd exercise-2-backup-bucket
terraform init
terraform validate
terraform plan
```

Override `bucket_name` in a real deployment (bucket names are globally
unique) - nothing here is applied, this repo only aims for a clean
`terraform plan`.

## Cross-account access

The bucket policy grants access to:

```
arn:aws:iam::123456789012:role/backup_uploader
```

as required by the task (this account/role is fictional). In a real setup
you would also need to make sure the `backup_uploader` role's own IAM policy
(in its own account, not managed here) grants `s3:PutObject` etc. on this
bucket's ARN - cross-account S3 access requires both sides (bucket policy +
identity policy) to allow the action.

## Alternative approaches considered

- **S3 Storage Lens / Intelligent-Tiering**: could reduce storage cost
  further for infrequently-accessed backups, but for a hard 180-day
  expiration the savings are marginal and it adds complexity - skipped here.
- **Object Lock GOVERNANCE mode instead of COMPLIANCE**: would allow an
  admin with `s3:BypassGovernanceRetention` to delete early if needed
  operationally. COMPLIANCE was chosen since the task explicitly wants
  180 days enforced, but GOVERNANCE is a legitimate alternative if some
  emergency deletion capability is desired.
- **AWS Backup service** instead of a plain S3 bucket: a fully managed
  option with built-in backup plans/lifecycle, but the task specifically
  asks for "an S3 bucket with the appropriate configuration", so a plain
  bucket + lifecycle/Object Lock was implemented directly.
