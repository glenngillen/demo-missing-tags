# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "ecs_api_gateway" {
  name              = "/ecs/api-gateway"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "ecs_user_service" {
  name              = "/ecs/user-service"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "ecs_order_service" {
  name              = "/ecs/order-service"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "ecs_payment_service" {
  name              = "/ecs/payment-service"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "ecs_inventory_service" {
  name              = "/ecs/inventory-service"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "ecs_notification_service"{
  name = "/ecs/notification-service"
  retention_in_days = 30
  kms_key_id = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "ecs_catalog_service" {
  name              = "/ecs/catalog-service"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "ecs_search_service" {
  name              = "/ecs/search-service"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "ecs_exec" {
  for_each          = toset(var.environments)
  name              = "/ecs/exec/${each.key}"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "lambda_process_order" {
  name              = "/aws/lambda/process-order"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_send_email" {
  name              = "/aws/lambda/send-email"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_resize_image" {
  name              = "/aws/lambda/resize-image"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_validate_payment" {
  name              = "/aws/lambda/validate-payment"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_sync_inventory" {
  name              = "/aws/lambda/sync-inventory"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_generate_report" {
  name              = "/aws/lambda/generate-report"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_cleanup_sessions" {
  name              = "/aws/lambda/cleanup-sessions"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_data_transformer" {
  name              = "/aws/lambda/data-transformer"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_notification_sender"{
  name = "/aws/lambda/notification-sender"
  retention_in_days = 14
  kms_key_id = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_cache_warmer" {
  name              = "/aws/lambda/cache-warmer"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_batch_processor" {
  name              = "/aws/lambda/batch-processor"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_stream_consumer" {
  name              = "/aws/lambda/stream-consumer"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_api_authorizer" {
  name              = "/aws/lambda/api-authorizer"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_migrate_data" {
  name              = "/aws/lambda/migrate-data"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "lambda_archive_records" {
  name              = "/aws/lambda/archive-records"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  for_each          = toset(var.environments)
  name              = "/aws/vpc/flowlogs/${each.key}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "rds" {
  for_each          = toset(var.environments)
  name              = "/aws/rds/${each.key}/postgresql"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "redis" {
  for_each          = toset(var.environments)
  name              = "/aws/elasticache/${each.key}/redis"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "eks" {
  for_each          = toset(["prod", "staging"])
  name              = "/aws/eks/${each.key}/cluster"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api-gateway/main"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "codebuild_api_gateway" {
  name              = "/aws/codebuild/api-gateway"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "codebuild_user_service" {
  name              = "/aws/codebuild/user-service"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "codebuild_order_service" {
  name              = "/aws/codebuild/order-service"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "codebuild_payment_service" {
  name              = "/aws/codebuild/payment-service"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "codebuild_inventory_service" {
  name              = "/aws/codebuild/inventory-service"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "codebuild_notification_service"{
  name = "/aws/codebuild/notification-service"
  retention_in_days = 14
  kms_key_id = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "codebuild_catalog_service" {
  name              = "/aws/codebuild/catalog-service"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}
resource "aws_cloudwatch_log_group" "codebuild_search_service" {
  name              = "/aws/codebuild/search-service"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "opensearch" {
  for_each          = toset(["prod", "staging"])
  name              = "/aws/opensearch/${each.key}"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "msk" {
  for_each          = toset(var.environments)
  name              = "/aws/msk/${each.key}"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/delivery"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-main"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/main"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "xray" {
  name              = "/aws/xray"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

# ============================================================
# CloudWatch Metric Alarms — RDS
# ============================================================

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
  ok_actions    = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 400
  alarm_description   = "RDS connection count is too high"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240  # 10 GB in bytes
  alarm_description   = "RDS free storage is running low"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-rds-read-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 0.1
  alarm_description   = "RDS read latency p99 exceeds 100ms"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-rds-write-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 0.2
  alarm_description   = "RDS write latency p99 exceeds 200ms"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

# ============================================================
# CloudWatch Metric Alarms — ElastiCache
# ============================================================

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-redis-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main[each.key].id
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

# ============================================================
# CloudWatch Metric Alarms — ECS
# ============================================================

locals {
  ecs_prod_cluster = aws_ecs_cluster.main["prod"].name
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_api_gateway"        {
  alarm_name = "prod-api-gateway-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "api-gateway"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_user_service"        {
  alarm_name = "prod-user-service-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "user-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_order_service"       {
  alarm_name = "prod-order-service-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "order-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_payment_service"     {
  alarm_name = "prod-payment-service-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "payment-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_inventory_service"   {
  alarm_name = "prod-inventory-service-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "inventory-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_notification_service"{
  alarm_name = "prod-notification-service-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "notification-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_catalog_service"     {
  alarm_name = "prod-catalog-service-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "catalog-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_search_service"      {
  alarm_name = "prod-search-service-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "search-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_api_gateway"        {
  alarm_name = "prod-api-gateway-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "api-gateway"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_memory_user_service"        {
  alarm_name = "prod-user-service-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "user-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_memory_order_service"       {
  alarm_name = "prod-order-service-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "order-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_memory_payment_service"     {
  alarm_name = "prod-payment-service-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "payment-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_memory_inventory_service"   {
  alarm_name = "prod-inventory-service-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "inventory-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_memory_notification_service"{
  alarm_name = "prod-notification-service-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "notification-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_memory_catalog_service"     {
  alarm_name = "prod-catalog-service-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "catalog-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "ecs_memory_search_service"      {
  alarm_name = "prod-search-service-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = 300
  statistic = "Average"
  threshold = 85
  dimensions = {
    ClusterName = local.ecs_prod_cluster
    ServiceName = "search-service"
  }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

# ============================================================
# CloudWatch Metric Alarms — ALB
# ============================================================

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 50

  dimensions = {
    LoadBalancer = aws_lb.main[each.key].arn_suffix
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
  ok_actions    = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 2.0

  dimensions = {
    LoadBalancer = aws_lb.main[each.key].arn_suffix
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy_hosts" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-alb-unhealthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.main[each.key].arn_suffix
    TargetGroup  = aws_lb_target_group.web[each.key].arn_suffix
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

# ============================================================
# CloudWatch Metric Alarms — Lambda
# ============================================================

resource "aws_cloudwatch_metric_alarm" "lambda_errors_process_order"      {
  alarm_name = "process-order-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.process_order.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_send_email"         {
  alarm_name = "send-email-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.send_email.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_resize_image"       {
  alarm_name = "resize-image-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.resize_image.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_validate_payment"   {
  alarm_name = "validate-payment-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.validate_payment.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_sync_inventory"     {
  alarm_name = "sync-inventory-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.sync_inventory.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_generate_report"    {
  alarm_name = "generate-report-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.generate_report.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_cleanup_sessions"   {
  alarm_name = "cleanup-sessions-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.cleanup_sessions.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_data_transformer"   {
  alarm_name = "data-transformer-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.data_transformer.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_notification_sender"{
  alarm_name = "notification-sender-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.notification_sender.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_cache_warmer"       {
  alarm_name = "cache-warmer-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.cache_warmer.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_batch_processor"    {
  alarm_name = "batch-processor-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.batch_processor.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_stream_consumer"    {
  alarm_name = "stream-consumer-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.stream_consumer.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_api_authorizer"     {
  alarm_name = "api-authorizer-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.api_authorizer.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_migrate_data"       {
  alarm_name = "migrate-data-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.migrate_data.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors_archive_records"    {
  alarm_name = "archive-records-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 10
  dimensions = { FunctionName = aws_lambda_function.archive_records.function_name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles_process_order"      {
  alarm_name = "process-order-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.process_order.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_send_email"         {
  alarm_name = "send-email-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.send_email.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_resize_image"       {
  alarm_name = "resize-image-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.resize_image.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_validate_payment"   {
  alarm_name = "validate-payment-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.validate_payment.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_sync_inventory"     {
  alarm_name = "sync-inventory-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.sync_inventory.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_generate_report"    {
  alarm_name = "generate-report-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.generate_report.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_cleanup_sessions"   {
  alarm_name = "cleanup-sessions-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.cleanup_sessions.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_data_transformer"   {
  alarm_name = "data-transformer-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.data_transformer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_notification_sender"{
  alarm_name = "notification-sender-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.notification_sender.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_cache_warmer"       {
  alarm_name = "cache-warmer-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.cache_warmer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_batch_processor"    {
  alarm_name = "batch-processor-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.batch_processor.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_stream_consumer"    {
  alarm_name = "stream-consumer-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.stream_consumer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_api_authorizer"     {
  alarm_name = "api-authorizer-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.api_authorizer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_migrate_data"       {
  alarm_name = "migrate-data-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.migrate_data.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_throttles_archive_records"    {
  alarm_name = "archive-records-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 100
  dimensions = { FunctionName = aws_lambda_function.archive_records.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration_process_order"      {
  alarm_name = "process-order-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.process_order.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_send_email"         {
  alarm_name = "send-email-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.send_email.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_resize_image"       {
  alarm_name = "resize-image-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.resize_image.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_validate_payment"   {
  alarm_name = "validate-payment-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.validate_payment.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_sync_inventory"     {
  alarm_name = "sync-inventory-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.sync_inventory.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_generate_report"    {
  alarm_name = "generate-report-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.generate_report.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_cleanup_sessions"   {
  alarm_name = "cleanup-sessions-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.cleanup_sessions.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_data_transformer"   {
  alarm_name = "data-transformer-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.data_transformer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_notification_sender"{
  alarm_name = "notification-sender-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.notification_sender.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_cache_warmer"       {
  alarm_name = "cache-warmer-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.cache_warmer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_batch_processor"    {
  alarm_name = "batch-processor-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.batch_processor.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_stream_consumer"    {
  alarm_name = "stream-consumer-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.stream_consumer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_api_authorizer"     {
  alarm_name = "api-authorizer-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.api_authorizer.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_migrate_data"       {
  alarm_name = "migrate-data-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.migrate_data.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "lambda_duration_archive_records"    {
  alarm_name = "archive-records-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 3
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = 300
  extended_statistic = "p99"
  threshold = 25000
  dimensions = { FunctionName = aws_lambda_function.archive_records.function_name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

# ============================================================
# CloudWatch Metric Alarms — SQS
# ============================================================

resource "aws_cloudwatch_metric_alarm" "sqs_depth_orders"        {
  alarm_name = "orders-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = 300
  statistic = "Maximum"
  threshold = 10000
  dimensions = { QueueName = aws_sqs_queue.orders.name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "sqs_depth_payments"      {
  alarm_name = "payments-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = 300
  statistic = "Maximum"
  threshold = 10000
  dimensions = { QueueName = aws_sqs_queue.payments.name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "sqs_depth_notifications" {
  alarm_name = "notifications-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = 300
  statistic = "Maximum"
  threshold = 10000
  dimensions = { QueueName = aws_sqs_queue.notifications.name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "sqs_depth_emails"        {
  alarm_name = "emails-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = 300
  statistic = "Maximum"
  threshold = 10000
  dimensions = { QueueName = aws_sqs_queue.emails.name }
  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_depth_orders"        {
  alarm_name = "orders-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = 60
  statistic = "Sum"
  threshold = 0
  dimensions = { QueueName = aws_sqs_queue.orders_dlq.name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "sqs_dlq_depth_payments"      {
  alarm_name = "payments-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = 60
  statistic = "Sum"
  threshold = 0
  dimensions = { QueueName = aws_sqs_queue.payments_dlq.name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}
resource "aws_cloudwatch_metric_alarm" "sqs_dlq_depth_notifications" {
  alarm_name = "notifications-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace = "AWS/SQS"
  period = 60
  statistic = "Sum"
  threshold = 0
  dimensions = { QueueName = aws_sqs_queue.notifications_dlq.name }
  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}

# ============================================================
# CloudWatch Metric Alarms — EC2 / ASG
# ============================================================

resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  for_each            = toset(var.environments)
  alarm_name          = "${each.key}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.worker[each.key].name
  }

  alarm_actions = [
    aws_autoscaling_policy.worker_scale_up[each.key].arn,
    aws_sns_topic.main["alerts"].arn
  ]
  ok_actions = [aws_autoscaling_policy.worker_scale_down[each.key].arn]
}

# ============================================================
# CloudWatch Dashboards
# ============================================================

resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "prod-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main["prod"].arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Request Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main["prod"].arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "5XX Errors"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main["prod"].id],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main["staging"].id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "ReplicationGroupId", aws_elasticache_replication_group.main["prod"].id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Redis CPU"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "microservices" {
  dashboard_name = "microservices-health"

  dashboard_body = jsonencode({
    widgets = [
      { type = "metric", x = 0,  y = 0, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "api-gateway"],        ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "api-gateway"]],        period = 300, stat = "Average", region = var.aws_region, title = "api-gateway Resources" } },
      { type = "metric", x = 6,  y = 0, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "user-service"],        ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "user-service"]],        period = 300, stat = "Average", region = var.aws_region, title = "user-service Resources" } },
      { type = "metric", x = 12, y = 0, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "order-service"],       ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "order-service"]],       period = 300, stat = "Average", region = var.aws_region, title = "order-service Resources" } },
      { type = "metric", x = 18, y = 0, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "payment-service"],     ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "payment-service"]],     period = 300, stat = "Average", region = var.aws_region, title = "payment-service Resources" } },
      { type = "metric", x = 0,  y = 6, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "inventory-service"],   ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "inventory-service"]],   period = 300, stat = "Average", region = var.aws_region, title = "inventory-service Resources" } },
      { type = "metric", x = 6,  y = 6, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "notification-service"], ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "notification-service"]], period = 300, stat = "Average", region = var.aws_region, title = "notification-service Resources" } },
      { type = "metric", x = 12, y = 6, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "catalog-service"],     ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "catalog-service"]],     period = 300, stat = "Average", region = var.aws_region, title = "catalog-service Resources" } },
      { type = "metric", x = 18, y = 6, width = 6, height = 6, properties = { metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "search-service"],      ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", "search-service"]],      period = 300, stat = "Average", region = var.aws_region, title = "search-service Resources" } }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "database" {
  dashboard_name = "database-performance"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", aws_db_instance.main["prod"].id],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", aws_db_instance.main["prod"].id]
          ]
          period = 60
          stat   = "p99"
          region = var.aws_region
          title  = "RDS Latency p99"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.main["prod"].id]
          ]
          period = 60
          stat   = "Maximum"
          region = var.aws_region
          title  = "RDS Connections"
        }
      }
    ]
  })
}

# ============================================================
# CloudWatch Composite Alarms
# ============================================================

resource "aws_cloudwatch_composite_alarm" "prod_critical" {
  alarm_name        = "prod-critical-composite"
  alarm_description = "Critical production alarm"

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.rds_cpu["prod"].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.alb_5xx["prod"].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.alb_healthy_hosts["prod"].alarm_name})"

  alarm_actions = [aws_sns_topic.main["security-alerts"].arn]
}

# ============================================================
# AWS Budgets
# ============================================================

resource "aws_budgets_budget" "monthly_total" {
  name         = "monthly-total-budget"
  budget_type  = "COST"
  limit_amount = "50000"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["finance@example.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["finance@example.com", "engineering-leads@example.com"]
  }
}

resource "aws_budgets_budget" "ec2_monthly" {
  name         = "ec2-monthly-budget"
  budget_type  = "COST"
  limit_amount = "20000"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["Amazon Elastic Compute Cloud - Compute"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["finance@example.com"]
  }
}

resource "aws_budgets_budget" "rds_monthly" {
  name         = "rds-monthly-budget"
  budget_type  = "COST"
  limit_amount = "10000"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["Amazon Relational Database Service"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["finance@example.com"]
  }
}
