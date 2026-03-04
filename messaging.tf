# ============================================================
# SQS Queues
# ============================================================

# Dead-letter queues first
resource "aws_sqs_queue" "dlq" {
  for_each                    = toset(var.sqs_queues)
  name                        = "${each.key}-dlq"
  message_retention_seconds   = 1209600  # 14 days
  kms_master_key_id           = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300
}

# Main queues
resource "aws_sqs_queue" "main" {
  for_each                    = toset(var.sqs_queues)
  name                        = each.key
  visibility_timeout_seconds  = 300
  message_retention_seconds   = 345600  # 4 days
  receive_wait_time_seconds   = 20
  kms_master_key_id           = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 5
  })
}

# High-throughput FIFO queues
resource "aws_sqs_queue" "fifo" {
  for_each                    = toset(["payments.fifo", "inventory-updates.fifo", "audit-events.fifo"])
  name                        = each.key
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 300
  message_retention_seconds   = 345600
  kms_master_key_id           = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_sqs_queue" "fifo_dlq" {
  for_each  = toset(["payments-dlq.fifo", "inventory-updates-dlq.fifo", "audit-events-dlq.fifo"])
  name      = each.key
  fifo_queue = true
  message_retention_seconds = 1209600
}

# SQS Queue Policies
resource "aws_sqs_queue_policy" "s3_notifications" {
  for_each  = toset(["image-processing"])
  queue_url = aws_sqs_queue.main[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main[each.key].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::*"
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "sns_subscriptions" {
  for_each  = toset(["notifications", "emails", "sms"])
  queue_url = aws_sqs_queue.main[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main[each.key].arn
      }
    ]
  })
}

# ============================================================
# SNS Topics
# ============================================================

resource "aws_sns_topic" "main" {
  for_each          = toset([
    "notifications", "alerts", "orders", "payments", "inventory",
    "user-events", "system-events", "security-alerts", "deployment-events",
    "error-alerts", "budget-alerts", "scaling-events", "backup-events",
    "compliance-events", "audit-events", "marketing-events", "analytics-events",
    "webhook-events", "replication-events", "health-events"
  ])
  name              = each.key
  kms_master_key_id = aws_kms_key.sns.id
}

# SNS → SQS subscriptions
resource "aws_sns_topic_subscription" "notifications_to_sqs" {
  topic_arn = aws_sns_topic.main["notifications"].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main["notifications"].arn

  filter_policy = jsonencode({
    event_type = ["notification", "alert"]
  })
}

resource "aws_sns_topic_subscription" "orders_to_sqs" {
  topic_arn = aws_sns_topic.main["orders"].arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main["orders"].arn
}

resource "aws_sns_topic_subscription" "alerts_to_email" {
  topic_arn = aws_sns_topic.main["alerts"].arn
  protocol  = "email"
  endpoint  = "ops-team@example.com"
}

resource "aws_sns_topic_subscription" "security_alerts_to_email" {
  topic_arn = aws_sns_topic.main["security-alerts"].arn
  protocol  = "email"
  endpoint  = "security@example.com"
}

resource "aws_sns_topic_subscription" "budget_alerts_to_email" {
  topic_arn = aws_sns_topic.main["budget-alerts"].arn
  protocol  = "email"
  endpoint  = "finance@example.com"
}

# ============================================================
# Kinesis Data Streams
# ============================================================

resource "aws_kinesis_stream" "events" {
  name             = "app-events"
  shard_count      = 10
  retention_period = 168  # 7 days

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.kinesis.arn

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_kinesis_stream" "clickstream" {
  name             = "clickstream"
  shard_count      = 20
  retention_period = 24

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.kinesis.arn

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_kinesis_stream" "audit_log" {
  name             = "audit-log-stream"
  shard_count      = 5
  retention_period = 168

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.kinesis.arn

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_kinesis_stream" "metrics" {
  name             = "metrics-stream"
  retention_period = 24

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.kinesis.arn

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_kinesis_stream_consumer" "events_lambda" {
  name       = "lambda-consumer"
  stream_arn = aws_kinesis_stream.events.arn
}

resource "aws_kinesis_stream_consumer" "events_firehose" {
  name       = "firehose-consumer"
  stream_arn = aws_kinesis_stream.events.arn
}

# ============================================================
# Kinesis Firehose
# ============================================================

resource "aws_kinesis_firehose_delivery_stream" "events_to_s3" {
  name        = "events-to-s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.events.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = aws_s3_bucket.app["data-lake"].arn
    prefix              = "events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/"

    buffering_size     = 128
    buffering_interval = 300
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = "S3Delivery"
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = "default"
        role_arn      = aws_iam_role.firehose.arn
        table_name    = "events"
      }
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "clickstream_to_s3" {
  name        = "clickstream-to-s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.clickstream.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = aws_s3_bucket.app["data-lake"].arn
    prefix              = "clickstream/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/clickstream/!{firehose:error-output-type}/"

    buffering_size     = 64
    buffering_interval = 60
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = "ClickstreamDelivery"
    }
  }
}

# ============================================================
# EventBridge
# ============================================================

resource "aws_cloudwatch_event_bus" "main" {
  name = "main-event-bus"
}

resource "aws_cloudwatch_event_rule" "cleanup_sessions" {
  name                = "cleanup-sessions-schedule"
  description         = "Trigger session cleanup Lambda daily"
  schedule_expression = "cron(0 3 * * ? *)"
  event_bus_name      = "default"
}

resource "aws_cloudwatch_event_target" "cleanup_sessions" {
  rule      = aws_cloudwatch_event_rule.cleanup_sessions.name
  target_id = "CleanupSessionsLambda"
  arn       = aws_lambda_function.main["cleanup-sessions"].arn
}

resource "aws_cloudwatch_event_rule" "cache_warmer" {
  name                = "cache-warmer-schedule"
  description         = "Warm cache every 15 minutes"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "cache_warmer" {
  rule      = aws_cloudwatch_event_rule.cache_warmer.name
  target_id = "CacheWarmerLambda"
  arn       = aws_lambda_function.main["cache-warmer"].arn
}

resource "aws_cloudwatch_event_rule" "generate_report" {
  name                = "daily-report-schedule"
  description         = "Generate daily reports"
  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_target" "generate_report" {
  rule      = aws_cloudwatch_event_rule.generate_report.name
  target_id = "GenerateReportLambda"
  arn       = aws_lambda_function.main["generate-report"].arn
}

resource "aws_cloudwatch_event_rule" "order_events" {
  name           = "order-events-rule"
  description    = "Route order events"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["app.orders"]
    detail-type = ["OrderCreated", "OrderUpdated", "OrderCancelled"]
  })
}

resource "aws_cloudwatch_event_target" "order_events_sqs" {
  rule           = aws_cloudwatch_event_rule.order_events.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  target_id      = "OrdersQueue"
  arn            = aws_sqs_queue.main["orders"].arn
}

resource "aws_cloudwatch_event_rule" "payment_events" {
  name           = "payment-events-rule"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["app.payments"]
    detail-type = ["PaymentProcessed", "PaymentFailed", "RefundIssued"]
  })
}

resource "aws_cloudwatch_event_target" "payment_events_sqs" {
  rule           = aws_cloudwatch_event_rule.payment_events.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  target_id      = "PaymentsQueue"
  arn            = aws_sqs_queue.fifo["payments.fifo"].arn
  sqs_target {
    message_group_id = "payments"
  }
}

resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "ec2-state-change"
  description = "Capture EC2 state changes"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["stopped", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_state_change_sns" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "EC2StateAlertSNS"
  arn       = aws_sns_topic.main["system-events"].arn
}

resource "aws_cloudwatch_event_rule" "rds_events" {
  name        = "rds-events"
  description = "Capture RDS events"

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["RDS DB Instance Event"]
  })
}

resource "aws_cloudwatch_event_target" "rds_events_sns" {
  rule      = aws_cloudwatch_event_rule.rds_events.name
  target_id = "RDSEventSNS"
  arn       = aws_sns_topic.main["alerts"].arn
}

resource "aws_cloudwatch_event_rule" "codepipeline_events" {
  name        = "codepipeline-events"
  description = "Capture CodePipeline state changes"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state = ["FAILED", "SUCCEEDED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "codepipeline_events_sns" {
  rule      = aws_cloudwatch_event_rule.codepipeline_events.name
  target_id = "CodePipelineSNS"
  arn       = aws_sns_topic.main["deployment-events"].arn
}

resource "aws_cloudwatch_event_rule" "health_check" {
  name                = "health-check-schedule"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "health_check" {
  rule      = aws_cloudwatch_event_rule.health_check.name
  target_id = "HealthCheckSFN"
  arn       = aws_sfn_state_machine.order_fulfillment.arn
  role_arn  = aws_iam_role.eventbridge.arn
}

resource "aws_cloudwatch_event_rule" "archive_records" {
  name                = "archive-records-schedule"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "archive_records" {
  rule      = aws_cloudwatch_event_rule.archive_records.name
  target_id = "ArchiveRecordsLambda"
  arn       = aws_lambda_function.main["archive-records"].arn
}
