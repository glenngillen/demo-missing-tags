# ============================================================
# S3 Buckets — Application
# ============================================================

resource "aws_s3_bucket" "app" {
  for_each = toset(var.s3_buckets)
  bucket   = "mycompany-${each.key}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "app" {
  for_each = toset(var.s3_buckets)
  bucket   = aws_s3_bucket.app[each.key].id

  versioning_configuration {
    status = contains(["backups", "archive", "terraform-state", "ml-models", "contracts"], each.key) ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  for_each = toset(var.s3_buckets)
  bucket   = aws_s3_bucket.app[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  for_each = toset(var.s3_buckets)
  bucket   = aws_s3_bucket.app[each.key].id

  block_public_acls       = !contains(["public-assets", "static-assets"], each.key)
  block_public_policy     = !contains(["public-assets", "static-assets"], each.key)
  ignore_public_acls      = !contains(["public-assets", "static-assets"], each.key)
  restrict_public_buckets = !contains(["public-assets", "static-assets"], each.key)
}

resource "aws_s3_bucket_lifecycle_configuration" "app" {
  for_each = toset(var.s3_buckets)
  bucket   = aws_s3_bucket.app[each.key].id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = contains(["logs", "access-logs", "cloudtrail-logs"], each.key) ? 90 : 2555
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "app" {
  for_each = toset([for b in var.s3_buckets : b if !contains(["access-logs"], b)])
  bucket   = aws_s3_bucket.app[each.key].id

  target_bucket = aws_s3_bucket.infra["access-logs"].id
  target_prefix = "s3/${each.key}/"
}

resource "aws_s3_bucket_notification" "uploads" {
  for_each = toset(["user-uploads", "product-images", "documents"])
  bucket   = aws_s3_bucket.app[each.key].id

  queue {
    queue_arn     = aws_sqs_queue.main["image-processing"].arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jpg"
  }

  queue {
    queue_arn     = aws_sqs_queue.main["image-processing"].arn
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
    "codebuild-cache", "terraform-state-backend", "cloudtrail"
  ])
  bucket = "mycompany-infra-${each.key}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "infra" {
  for_each = toset([
    "access-logs", "audit-logs", "codepipeline-artifacts",
    "codebuild-cache", "terraform-state-backend", "cloudtrail"
  ])
  bucket = aws_s3_bucket.infra[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "infra" {
  for_each = toset([
    "access-logs", "audit-logs", "codepipeline-artifacts",
    "codebuild-cache", "terraform-state-backend", "cloudtrail"
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
    "codebuild-cache", "terraform-state-backend", "cloudtrail"
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
    "codebuild-cache", "terraform-state-backend", "cloudtrail"
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
