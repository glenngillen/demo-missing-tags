# ============================================================
# S3 Buckets — Application (explicit definitions)
# ============================================================

resource "aws_s3_bucket" "raw_data" {
  bucket = "mycompany-raw-data-${random_id.suffix.hex}"
  tags   = { Service = "data", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "raw_data" {
  bucket                  = aws_s3_bucket.raw_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "raw_data" {
  bucket        = aws_s3_bucket.raw_data.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/raw-data/"
}

resource "aws_s3_bucket" "processed_data" {
  bucket = "mycompany-processed-data-${random_id.suffix.hex}"
  tags   = { Service = "data", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "processed_data" {
  bucket                  = aws_s3_bucket.processed_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "processed_data" {
  bucket        = aws_s3_bucket.processed_data.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/processed-data/"
}

resource "aws_s3_bucket" "backups" {
  bucket = "mycompany-backups-${random_id.suffix.hex}"
  tags   = { Service = "backup", Owner = "sre", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "backups" {
  bucket        = aws_s3_bucket.backups.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/backups/"
}

resource "aws_s3_bucket" "logs" {
  bucket = "mycompany-logs-${random_id.suffix.hex}"
  tags   = { Service = "logging", Owner = "sre", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    expiration { days = 90 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "logs" {
  bucket        = aws_s3_bucket.logs.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/logs/"
}

resource "aws_s3_bucket" "user_uploads" {
  bucket = "mycompany-user-uploads-${random_id.suffix.hex}"
  tags   = { Service = "media", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "user_uploads" {
  bucket                  = aws_s3_bucket.user_uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "user_uploads" {
  bucket        = aws_s3_bucket.user_uploads.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/user-uploads/"
}

resource "aws_s3_bucket" "product_images" {
  bucket = "mycompany-product-images-${random_id.suffix.hex}"
  tags   = { Service = "media", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "product_images" {
  bucket                  = aws_s3_bucket.product_images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "product_images" {
  bucket = aws_s3_bucket.product_images.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "product_images" {
  bucket        = aws_s3_bucket.product_images.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/product-images/"
}

resource "aws_s3_bucket" "documents" {
  bucket = "mycompany-documents-${random_id.suffix.hex}"
  tags   = { Service = "documents", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = aws_s3_bucket.documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "documents" {
  bucket        = aws_s3_bucket.documents.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/documents/"
}

resource "aws_s3_bucket" "audit_logs" {
  bucket = "mycompany-audit-logs-${random_id.suffix.hex}"
  tags   = { Service = "audit", Owner = "secops", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "audit_logs" {
  bucket        = aws_s3_bucket.audit_logs.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/audit-logs/"
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "mycompany-access-logs-${random_id.suffix.hex}"
  tags   = { Service = "logging", Owner = "sre", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    expiration { days = 90 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

# No logging resource for access_logs (it's the target)

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "mycompany-cloudtrail-logs-${random_id.suffix.hex}"
  tags   = { Service = "audit", Owner = "secops", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    expiration { days = 90 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "cloudtrail_logs" {
  bucket        = aws_s3_bucket.cloudtrail_logs.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/cloudtrail-logs/"
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "mycompany-codepipeline-artifacts-${random_id.suffix.hex}"
  tags   = { Service = "cicd", Owner = "platform", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket                  = aws_s3_bucket.codepipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "codepipeline_artifacts" {
  bucket        = aws_s3_bucket.codepipeline_artifacts.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/codepipeline-artifacts/"
}

resource "aws_s3_bucket" "static_assets" {
  bucket = "mycompany-static-assets-${random_id.suffix.hex}"
  tags   = { Service = "web", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket                  = aws_s3_bucket.static_assets.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_lifecycle_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "static_assets" {
  bucket        = aws_s3_bucket.static_assets.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/static-assets/"
}

resource "aws_s3_bucket" "media" {
  bucket = "mycompany-media-${random_id.suffix.hex}"
  tags   = { Service = "media", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "media" {
  bucket        = aws_s3_bucket.media.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/media/"
}

resource "aws_s3_bucket" "data_lake" {
  bucket = "mycompany-data-lake-${random_id.suffix.hex}"
  tags   = { Service = "data", Owner = "appdev", Environment = "Prod" }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration { status = "Disabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket                  = aws_s3_bucket.data_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"
    transition { days = 30; storage_class = "STANDARD_IA" }
    transition { days = 90; storage_class = "GLACIER" }
    transition { days = 365; storage_class = "DEEP_ARCHIVE" }
    expiration { days = 2555 }
  }
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_s3_bucket_logging" "data_lake" {
  bucket        = aws_s3_bucket.data_lake.id
  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/data-lake/"
}

# S3 bucket notifications for upload pipelines
resource "aws_s3_bucket_notification" "user_uploads" {
  bucket = aws_s3_bucket.user_uploads.id

  queue {
    queue_arn     = aws_sqs_queue.image_processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }

  queue {
    queue_arn     = aws_sqs_queue.image_processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".png"
  }

  topic {
    topic_arn = aws_sns_topic.main["notifications"].arn
    events    = ["s3:ObjectRemoved:*"]
  }
}

resource "aws_s3_bucket_notification" "product_images" {
  bucket = aws_s3_bucket.product_images.id

  queue {
    queue_arn     = aws_sqs_queue.image_processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }

  queue {
    queue_arn     = aws_sqs_queue.image_processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".png"
  }

  topic {
    topic_arn = aws_sns_topic.main["notifications"].arn
    events    = ["s3:ObjectRemoved:*"]
  }
}

resource "aws_s3_bucket_notification" "documents" {
  bucket = aws_s3_bucket.documents.id

  queue {
    queue_arn     = aws_sqs_queue.image_processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }

  queue {
    queue_arn     = aws_sqs_queue.image_processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".png"
  }

  topic {
    topic_arn = aws_sns_topic.main["notifications"].arn
    events    = ["s3:ObjectRemoved:*"]
  }
}

# ============================================================
# S3 Buckets — Infrastructure
# ============================================================

resource "aws_s3_bucket" "infra" {
  for_each = toset([
    "access-logs", "audit-logs", "codepipeline-artifacts",
    "codebuild-cache", "terraform-state-backend", "cloudtrail",
    "config-snapshots"
  ])
  bucket = "mycompany-infra-${each.key}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "infra" {
  for_each = toset([
    "access-logs", "audit-logs", "codepipeline-artifacts",
    "codebuild-cache", "terraform-state-backend", "cloudtrail",
    "config-snapshots"
  ])
  bucket = aws_s3_bucket.infra[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "infra" {
  for_each = toset([
    "access-logs", "audit-logs", "codepipeline-artifacts",
    "codebuild-cache", "terraform-state-backend", "cloudtrail",
    "config-snapshots"
  ])
  bucket = aws_s3_bucket.infra[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "infra" {
  for_each = toset([
    "access-logs", "audit-logs", "codepipeline-artifacts",
    "codebuild-cache", "terraform-state-backend", "cloudtrail",
    "config-snapshots"
  ])
  bucket = aws_s3_bucket.infra[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "infra" {
  for_each = toset([
    "access-logs", "audit-logs", "codepipeline-artifacts",
    "codebuild-cache", "terraform-state-backend", "cloudtrail",
    "config-snapshots"
  ])
  bucket = aws_s3_bucket.infra[each.key].id

  rule {
    id     = "lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ============================================================
# S3 Cross-Region Replication (for critical buckets)
# ============================================================

resource "aws_s3_bucket" "dr_replica" {
  for_each = toset(["terraform-state-backend", "backups", "audit-logs"])
  provider  = aws.secondary
  bucket    = "mycompany-dr-${each.key}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "dr_replica" {
  for_each = toset(["terraform-state-backend", "backups", "audit-logs"])
  provider  = aws.secondary
  bucket    = aws_s3_bucket.dr_replica[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "s3_replication" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_replication" {
  name = "s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.infra["terraform-state-backend"].arn]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.infra["terraform-state-backend"].arn}/*"]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.dr_replica["terraform-state-backend"].arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  role       = aws_iam_role.s3_replication.name
  policy_arn = aws_iam_policy.s3_replication.arn
}

resource "aws_s3_bucket_replication_configuration" "terraform_state" {
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.infra["terraform-state-backend"].id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr_replica["terraform-state-backend"].arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [aws_s3_bucket_versioning.infra]
}

# ============================================================
# CloudTrail
# ============================================================

resource "aws_cloudtrail" "main" {
  name                          = "main-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.infra["cloudtrail"].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}

resource "aws_cloudtrail" "data_events" {
  name               = "data-events-cloudtrail"
  s3_bucket_name     = aws_s3_bucket.infra["cloudtrail"].id
  is_multi_region_trail = false

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::DynamoDB::Table"
      values = ["arn:aws:dynamodb"]
    }
  }
}
