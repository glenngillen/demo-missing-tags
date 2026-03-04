# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "ecs" {
  for_each          = toset(var.microservices)
  name              = "/ecs/${each.key}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "ecs_exec" {
  for_each          = toset(var.environments)
  name              = "/ecs/exec/${each.key}"
  retention_in_days = 7
  kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each          = toset(var.lambda_functions)
  name              = "/aws/lambda/${each.key}"
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

resource "aws_cloudwatch_log_group" "codebuild" {
  for_each          = toset(var.microservices)
  name              = "/aws/codebuild/${each.key}"
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
  statistic           = "p99"
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
  statistic           = "p99"
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

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each            = toset(var.microservices)
  alarm_name          = "prod-${each.key}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85

  dimensions = {
    ClusterName = aws_ecs_cluster.main["prod"].name
    ServiceName = each.key
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  for_each            = toset(var.microservices)
  alarm_name          = "prod-${each.key}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85

  dimensions = {
    ClusterName = aws_ecs_cluster.main["prod"].name
    ServiceName = each.key
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

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each            = toset(var.lambda_functions)
  alarm_name          = "${each.key}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    FunctionName = aws_lambda_function.main[each.key].function_name
  }

  alarm_actions = [aws_sns_topic.main["error-alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each            = toset(var.lambda_functions)
  alarm_name          = "${each.key}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 100

  dimensions = {
    FunctionName = aws_lambda_function.main[each.key].function_name
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each            = toset(var.lambda_functions)
  alarm_name          = "${each.key}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p99"
  threshold           = 25000  # 25 seconds

  dimensions = {
    FunctionName = aws_lambda_function.main[each.key].function_name
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

# ============================================================
# CloudWatch Metric Alarms — SQS
# ============================================================

resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  for_each            = toset(["orders", "payments", "notifications", "emails"])
  alarm_name          = "${each.key}-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 10000

  dimensions = {
    QueueName = aws_sqs_queue.main[each.key].name
  }

  alarm_actions = [aws_sns_topic.main["alerts"].arn]
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_depth" {
  for_each            = toset(["orders", "payments", "notifications"])
  alarm_name          = "${each.key}-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0

  dimensions = {
    QueueName = aws_sqs_queue.dlq[each.key].name
  }

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
      for idx, svc in var.microservices : {
        type   = "metric"
        x      = (idx % 4) * 6
        y      = floor(idx / 4) * 6
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", svc],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main["prod"].name, "ServiceName", svc]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "${svc} Resources"
        }
      }
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
