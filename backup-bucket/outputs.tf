output "bucket_id" {
  description = "Name of the backup bucket."
  value       = aws_s3_bucket.backup.id
}

output "bucket_arn" {
  description = "ARN of the backup bucket."
  value       = aws_s3_bucket.backup.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption (null when use_kms = false, i.e. SSE-S3 is used)."
  value       = var.use_kms ? aws_kms_key.backup[0].arn : null
}
