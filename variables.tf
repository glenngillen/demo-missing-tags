variable "aws_region" {
  default = "us-east-1"
}

variable "secondary_region" {
  default = "us-west-2"
}

variable "environments" {
  default = ["prod", "staging", "dev"]
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidrs" {
  default = {
    prod    = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    dev     = "10.2.0.0/16"
  }
}

variable "db_password" {
  default   = "ChangeMePlease123!"
  sensitive = true
}

variable "app_count" {
  default = 10
}

variable "microservices" {
  default = [
    "api-gateway", "auth", "user", "order", "payment",
    "inventory", "notification", "reporting", "search", "recommendation",
    "cart", "checkout", "shipping", "catalog", "review",
    "analytics", "audit", "scheduler", "worker", "webhook"
  ]
}

variable "lambda_functions" {
  default = [
    "process-order", "send-email", "resize-image", "validate-payment",
    "sync-inventory", "generate-report", "cleanup-sessions", "index-search",
    "audit-logger", "webhook-dispatcher", "data-transformer", "file-processor",
    "notification-sender", "cache-warmer", "dead-letter-handler", "retry-processor",
    "event-router", "batch-processor", "stream-consumer", "api-authorizer",
    "custom-authorizer", "pre-token-hook", "post-confirm-hook", "pre-signup-hook",
    "migrate-data", "archive-records", "compress-logs", "export-csv"
  ]
}

variable "sqs_queues" {
  default = [
    "orders", "payments", "notifications", "emails", "sms",
    "inventory-updates", "audit-events", "webhooks", "reports",
    "image-processing", "search-indexing", "data-sync", "cache-invalidation",
    "user-events", "analytics-events", "dead-letter-orders", "dead-letter-payments",
    "dead-letter-notifications", "batch-jobs", "scheduled-tasks",
    "order-fulfillment", "shipping-updates", "review-moderation",
    "recommendation-updates", "catalog-updates", "price-updates",
    "stock-alerts", "fraud-detection", "compliance-events", "backup-jobs"
  ]
}

variable "s3_buckets" {
  default = [
    "raw-data", "processed-data", "archive", "backups", "logs",
    "user-uploads", "product-images", "reports", "exports", "imports",
    "static-assets", "media", "documents", "invoices", "contracts",
    "ml-training-data", "ml-models", "data-lake", "audit-logs", "access-logs",
    "cloudtrail-logs", "config-snapshots", "codepipeline-artifacts",
    "codebuild-cache", "lambda-deployments", "terraform-state", "scripts",
    "templates", "public-assets", "private-assets"
  ]
}

variable "dynamodb_tables" {
  default = [
    "users", "sessions", "orders", "order-items", "products",
    "inventory", "carts", "reviews", "ratings", "recommendations",
    "notifications", "audit-log", "feature-flags", "config",
    "rate-limits", "locks", "counters", "events", "webhooks", "jobs"
  ]
}

variable "instance_types" {
  default = {
    prod    = "m5.2xlarge"
    staging = "m5.large"
    dev     = "t3.medium"
  }
}

variable "rds_instance_classes" {
  default = {
    prod    = "db.r5.2xlarge"
    staging = "db.m5.large"
    dev     = "db.t3.medium"
  }
}
