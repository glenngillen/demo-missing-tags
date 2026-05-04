# ============================================================
# Security Groups
# ============================================================

resource "aws_security_group" "rds" {
  for_each    = toset(var.environments)
  name        = "${each.key}-rds"
  description = "RDS security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks[each.key].id]
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_bastion[each.key].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis" {
  for_each    = toset(var.environments)
  name        = "${each.key}-redis"
  description = "Redis security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks[each.key].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "msk" {
  for_each    = toset(var.environments)
  name        = "${each.key}-msk"
  description = "MSK Kafka security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidrs[each.key]]
  }

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidrs[each.key]]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "opensearch" {
  for_each    = toset(var.environments)
  name        = "${each.key}-opensearch"
  description = "OpenSearch security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidrs[each.key]]
  }

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidrs[each.key]]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================
# RDS — Parameter Groups
# ============================================================

resource "aws_db_parameter_group" "postgres14" {
  for_each = toset(var.environments)
  name     = "${each.key}-postgres14"
  family   = "postgres14"

  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"
  }

  parameter {
    name  = "max_connections"
    value = "500"
  }

  parameter {
    name  = "wal_level"
    value = "logical"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "autovacuum_vacuum_scale_factor"
    value = "0.1"
  }
}

resource "aws_db_parameter_group" "mysql8" {
  for_each = toset(var.environments)
  name     = "${each.key}-mysql8"
  family   = "mysql8.0"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "1"
  }
}


# RDS Monitoring Role
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ============================================================
# ElastiCache — Redis (per env)
# ============================================================

resource "aws_elasticache_parameter_group" "redis7" {
  for_each = toset(var.environments)
  name     = "${each.key}-redis7"
  family   = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "activerehashing"
    value = "yes"
  }

  parameter {
    name  = "hz"
    value = "15"
  }
}

# Dedicated session cache
resource "aws_elasticache_replication_group" "sessions" {
  replication_group_id = "prod-sessions"
  description          = "Dedicated Redis for session storage"

  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.r6g.large"
  num_cache_clusters   = 3
  parameter_group_name = aws_elasticache_parameter_group.redis7["prod"].name
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main["prod"].name
  security_group_ids = [aws_security_group.redis["prod"].id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result
  kms_key_id                 = aws_kms_key.elasticache.arn

  automatic_failover_enabled = true
  multi_az_enabled           = true

  snapshot_retention_limit = 3
}

# ============================================================
# DynamoDB Tables
# ============================================================

resource "aws_dynamodb_table" "users" {
  name         = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "sessions" {
  name         = "sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "orders" {
  name         = "orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }


}

resource "aws_dynamodb_table" "order_items" {
  name         = "order-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "products" {
  name         = "products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "inventory" {
  name         = "inventory"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "carts" {
  name         = "carts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "feature_flags" {
  name         = "feature-flags"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "config" {
  name         = "config"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "rate_limits" {
  name         = "rate-limits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

}

resource "aws_dynamodb_table" "orders_with_gsi" {
  name         = "orders-v2"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"
  range_key    = "created_at"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "user-orders-index"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "created_at"
    projection_type = "INCLUDE"
    non_key_attributes = ["order_id", "user_id", "total_amount"]
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
}

resource "aws_dynamodb_table" "time_series_metrics" {
  name         = "time-series-metrics"
  billing_mode = "PROVISIONED"
  hash_key     = "metric_name"
  range_key    = "timestamp"

  read_capacity  = 100
  write_capacity = 200

  attribute {
    name = "metric_name"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.rds.arn
  }
}

resource "aws_appautoscaling_target" "dynamodb_read" {
  max_capacity       = 1000
  min_capacity       = 100
  resource_id        = "table/${aws_dynamodb_table.time_series_metrics.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "dynamodb_write" {
  max_capacity       = 2000
  min_capacity       = 200
  resource_id        = "table/${aws_dynamodb_table.time_series_metrics.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_read" {
  name               = "time-series-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_read.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_read.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_read.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "dynamodb_write" {
  name               = "time-series-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_write.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_write.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_write.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}

# ============================================================
# OpenSearch (Elasticsearch)
# ============================================================

resource "aws_opensearch_domain" "main" {
  for_each      = toset(["prod", "staging"])
  domain_name   = "${each.key}-search"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type            = each.key == "prod" ? "m6g.2xlarge.search" : "t3.small.search"
    instance_count           = each.key == "prod" ? 3 : 1
    dedicated_master_enabled = each.key == "prod"
    dedicated_master_type    = each.key == "prod" ? "m6g.large.search" : null
    dedicated_master_count   = each.key == "prod" ? 3 : null
    zone_awareness_enabled   = each.key == "prod"

    dynamic "zone_awareness_config" {
      for_each = each.key == "prod" ? [1] : []
      content {
        availability_zone_count = 3
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = each.key == "prod" ? 1000 : 100
    iops        = each.key == "prod" ? 6000 : 3000
    throughput  = each.key == "prod" ? 250 : 125
  }

  vpc_options {
    subnet_ids = each.key == "prod" ? [
      aws_subnet.private["prod-0"].id,
      aws_subnet.private["prod-1"].id,
      aws_subnet.private["prod-2"].id,
    ] : [aws_subnet.private["staging-0"].id]

    security_group_ids = [aws_security_group.opensearch[each.key].id]
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.rds.arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.db_master.result
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch[each.key].arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch[each.key].arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch[each.key].arn
    log_type                 = "ES_APPLICATION_LOGS"
  }
}

# ============================================================
# Redshift
# ============================================================

resource "aws_redshift_subnet_group" "main" {
  name = "redshift-subnet-group"

  subnet_ids = [
    aws_subnet.database["prod-0"].id,
    aws_subnet.database["prod-1"].id,
    aws_subnet.database["prod-2"].id,
  ]
}

resource "aws_redshift_parameter_group" "main" {
  name   = "redshift-params"
  family = "redshift-1.0"

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "query_group"
    value = "default"
  }
}

resource "aws_redshift_cluster" "main" {
  cluster_identifier        = "prod-redshift"
  database_name             = "datawarehouse"
  master_username           = "redshiftadmin"
  master_password           = random_password.db_master.result
  node_type                 = "ra3.4xlarge"
  cluster_type              = "multi-node"
  number_of_nodes           = 4
  cluster_subnet_group_name = aws_redshift_subnet_group.main.name
  cluster_parameter_group_name = aws_redshift_parameter_group.main.name

  vpc_security_group_ids = [aws_security_group.rds["prod"].id]

  encrypted  = true
  kms_key_id = aws_kms_key.rds.arn

  automated_snapshot_retention_period = 35
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "prod-redshift-final"

  enhanced_vpc_routing = true
  publicly_accessible  = false

}

resource "aws_redshift_logging" "main" {
  cluster_identifier = aws_redshift_cluster.main.id
  bucket_name        = aws_s3_bucket.infra["audit-logs"].id
  s3_key_prefix      = "redshift/"
}

# ============================================================
# MSK (Managed Kafka)
# ============================================================

resource "aws_msk_cluster" "main" {
  for_each              = toset(["prod", "staging"])
  cluster_name          = "${each.key}-kafka"
  kafka_version         = "3.5.1"
  number_of_broker_nodes = each.key == "prod" ? 6 : 3

  broker_node_group_info {
    instance_type = each.key == "prod" ? "kafka.m5.2xlarge" : "kafka.m5.large"

    client_subnets = each.key == "prod" ? [
      aws_subnet.private["prod-0"].id,
      aws_subnet.private["prod-1"].id,
      aws_subnet.private["prod-2"].id,
    ] : [
      aws_subnet.private["staging-0"].id,
      aws_subnet.private["staging-1"].id,
      aws_subnet.private["staging-2"].id,
    ]

    security_groups = [aws_security_group.msk[each.key].id]

    storage_info {
      ebs_storage_info {
        provisioned_throughput {
          enabled           = each.key == "prod"
          volume_throughput = each.key == "prod" ? 250 : null
        }
        volume_size = each.key == "prod" ? 2000 : 200
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
    encryption_at_rest_kms_key_arn = aws_kms_key.kinesis.arn
  }

  client_authentication {
    sasl {
      iam   = true
      scram = true
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk[each.key].name
      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.logs.id
        prefix  = "${each.key}/msk/"
      }
    }
  }
}

resource "aws_msk_configuration" "main" {
  name              = "kafka-config"
  kafka_versions    = ["3.5.1"]
  server_properties = <<EOF
auto.create.topics.enable=false
delete.topic.enable=true
log.retention.hours=168
num.partitions=6
default.replication.factor=3
min.insync.replicas=2
compression.type=lz4
EOF
}

resource "aws_msk_scram_secret_association" "main" {
  cluster_arn     = aws_msk_cluster.main["prod"].arn
  secret_arn_list = [aws_secretsmanager_secret.api_keys["prod"].arn]
}
