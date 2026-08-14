resource "aws_s3_bucket" "backup" {
  bucket              = var.bucket_name
  object_lock_enabled = true

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "backup" {
  count = var.use_kms ? 1 : 0

  description             = "CMK for ${var.bucket_name} backup bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "backup" {
  count = var.use_kms ? 1 : 0

  name          = "alias/${var.bucket_name}-backup"
  target_key_id = aws_kms_key.backup[0].key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.use_kms ? "aws:kms" : "AES256"
      kms_master_key_id = var.use_kms ? aws_kms_key.backup[0].arn : null
    }
    bucket_key_enabled = var.use_kms
  }
}

resource "aws_s3_bucket_object_lock_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.backup]
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "expire-backups-after-retention"
    status = "Enabled"

    filter {}

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.backup]
}

data "aws_iam_policy_document" "backup" {
  statement {
    sid    = "AllowBackupUploaderUpload"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.uploader_role_arn]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectRetention",
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.backup.arn,
      "${aws_s3_bucket.backup.arn}/*",
    ]
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.backup.arn,
      "${aws_s3_bucket.backup.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.backup.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = var.use_kms ? ["aws:kms"] : ["AES256"]
    }
  }
}

resource "aws_s3_bucket_policy" "backup" {
  bucket = aws_s3_bucket.backup.id
  policy = data.aws_iam_policy_document.backup.json

  depends_on = [aws_s3_bucket_public_access_block.backup]
}
