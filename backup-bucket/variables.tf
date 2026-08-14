variable "region" {
  description = "AWS region for the backup bucket."
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Globally unique name of the backup bucket."
  type        = string
  default     = "acme-app-backups-example"
}

variable "retention_days" {
  description = <<-EOT
    How long backups must be kept, in days. Drives both the S3 Object Lock
    retention period (protects against early/accidental/malicious deletion)
    and the lifecycle expiration rule (guarantees objects are deleted once
    the retention window is over, per the "180 days and no more" requirement).
  EOT
  type    = number
  default = 180
}

variable "noncurrent_version_expiration_days" {
  description = "How long to keep noncurrent (overwritten) object versions before they are permanently deleted."
  type        = number
  default     = 30
}

variable "use_kms" {
  description = <<-EOT
    If true, objects are encrypted with a dedicated customer-managed KMS key
    (more control, audit trail via CloudTrail, extra cost ~$1/month + request
    charges). If false, SSE-S3 (AES256) is used, which is free and still
    encrypts everything at rest. Defaults to false to keep this example free.
  EOT
  type    = bool
  default = false
}

variable "uploader_role_arn" {
  description = "ARN of the IAM role (in the other/foreign account) that is allowed to upload backups into this bucket."
  type        = string
  default     = "arn:aws:iam::123456789012:role/backup_uploader"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "devops-homework"
    Purpose   = "backup-storage"
    ManagedBy = "terraform"
  }
}
