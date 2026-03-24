# ============================================================
# KMS Keys
# ============================================================

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "rds" {
  name          = "alias/rds-encryption"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3" {
  name          = "alias/s3-encryption"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_kms_key" "ssm" {
  description             = "KMS key for SSM Parameter Store"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/ssm-encryption"
  target_key_id = aws_kms_key.ssm.key_id
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/secrets-encryption"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/cloudwatch-encryption"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

resource "aws_kms_key" "elasticache" {
  description             = "KMS key for ElastiCache"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/elasticache-encryption"
  target_key_id = aws_kms_key.elasticache.key_id
}

resource "aws_kms_key" "sqs" {
  description             = "KMS key for SQS queues"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "sqs" {
  name          = "alias/sqs-encryption"
  target_key_id = aws_kms_key.sqs.key_id
}

resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS topics"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "sns" {
  name          = "alias/sns-encryption"
  target_key_id = aws_kms_key.sns.key_id
}

resource "aws_kms_key" "kinesis" {
  description             = "KMS key for Kinesis streams"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "kinesis" {
  name          = "alias/kinesis-encryption"
  target_key_id = aws_kms_key.kinesis.key_id
}

# ============================================================
# Security Groups
# ============================================================

resource "aws_security_group" "alb_public" {
  for_each    = toset(var.environments)
  name        = "${each.key}-alb-public"
  description = "Public ALB security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_internal" {
  for_each    = toset(var.environments)
  name        = "${each.key}-alb-internal"
  description = "Internal ALB security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidrs[each.key]]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "ecs_tasks" {
  for_each    = toset(var.environments)
  name        = "${each.key}-ecs-tasks"
  description = "ECS tasks security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public[each.key].id]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidrs[each.key]]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_bastion" {
  for_each    = toset(var.environments)
  name        = "${each.key}-bastion"
  description = "Bastion host security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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

resource "aws_security_group" "eks_cluster" {
  for_each    = toset(["prod", "staging"])
  name        = "${each.key}-eks-cluster"
  description = "EKS cluster security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes" {
  for_each    = toset(["prod", "staging"])
  name        = "${each.key}-eks-nodes"
  description = "EKS nodes security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster[each.key].id]
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

resource "aws_security_group" "vpc_endpoints" {
  for_each    = toset(var.environments)
  name        = "${each.key}-vpc-endpoints"
  description = "VPC endpoints security group for ${each.key}"
  vpc_id      = aws_vpc.main[each.key].id

  ingress {
    from_port   = 443
    to_port     = 443
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
# IAM — Roles and Policies
# ============================================================

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "step_functions_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# ECS Execution Role
resource "aws_iam_role" "ecs_execution" {
  for_each           = toset(var.environments)
  name               = "${each.key}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  for_each   = toset(var.environments)
  role       = aws_iam_role.ecs_execution[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_execution_ssm" {
  for_each    = toset(var.environments)
  name        = "${each.key}-ecs-execution-ssm"
  description = "Allows ECS tasks to read SSM parameters in ${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ssm" {
  for_each   = toset(var.environments)
  role       = aws_iam_role.ecs_execution[each.key].name
  policy_arn = aws_iam_policy.ecs_execution_ssm[each.key].arn
}

# ECS Task Roles per microservice
locals {
  ecs_task_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_api_gateway" {
  name               = "ecs-task-api-gateway"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_api_gateway" {
  name   = "ecs-task-api-gateway-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_api_gateway" {
  role       = aws_iam_role.ecs_task_api_gateway.name
  policy_arn = aws_iam_policy.ecs_task_base_api_gateway.arn
}

resource "aws_iam_role" "ecs_task_user_service" {
  name               = "ecs-task-user-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_user_service" {
  name   = "ecs-task-user-service-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_user_service" {
  role       = aws_iam_role.ecs_task_user_service.name
  policy_arn = aws_iam_policy.ecs_task_base_user_service.arn
}

resource "aws_iam_role" "ecs_task_order_service" {
  name               = "ecs-task-order-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_order_service" {
  name   = "ecs-task-order-service-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_order_service" {
  role       = aws_iam_role.ecs_task_order_service.name
  policy_arn = aws_iam_policy.ecs_task_base_order_service.arn
}

resource "aws_iam_role" "ecs_task_payment_service" {
  name               = "ecs-task-payment-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_payment_service" {
  name   = "ecs-task-payment-service-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_payment_service" {
  role       = aws_iam_role.ecs_task_payment_service.name
  policy_arn = aws_iam_policy.ecs_task_base_payment_service.arn
}

resource "aws_iam_role" "ecs_task_inventory_service" {
  name               = "ecs-task-inventory-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_inventory_service" {
  name   = "ecs-task-inventory-service-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_inventory_service" {
  role       = aws_iam_role.ecs_task_inventory_service.name
  policy_arn = aws_iam_policy.ecs_task_base_inventory_service.arn
}

resource "aws_iam_role" "ecs_task_notification_service" {
  name               = "ecs-task-notification-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_notification_service" {
  name   = "ecs-task-notification-service-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_notification_service" {
  role       = aws_iam_role.ecs_task_notification_service.name
  policy_arn = aws_iam_policy.ecs_task_base_notification_service.arn
}

resource "aws_iam_role" "ecs_task_catalog_service" {
  name               = "ecs-task-catalog-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_catalog_service" {
  name   = "ecs-task-catalog-service-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_catalog_service" {
  role       = aws_iam_role.ecs_task_catalog_service.name
  policy_arn = aws_iam_policy.ecs_task_base_catalog_service.arn
}

resource "aws_iam_role" "ecs_task_search_service" {
  name               = "ecs-task-search-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}
resource "aws_iam_policy" "ecs_task_base_search_service" {
  name   = "ecs-task-search-service-base"
  policy = local.ecs_task_policy
}
resource "aws_iam_role_policy_attachment" "ecs_task_base_search_service" {
  role       = aws_iam_role.ecs_task_search_service.name
  policy_arn = aws_iam_policy.ecs_task_base_search_service.arn
}

# Lambda Roles
locals {
  lambda_base_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sns:Publish",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "ssm:GetParameter",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_process_order" {
  name               = "lambda-process-order"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_process_order" {
  role       = aws_iam_role.lambda_process_order.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_process_order" {
  name   = "lambda-process-order-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_process_order" {
  role       = aws_iam_role.lambda_process_order.name
  policy_arn = aws_iam_policy.lambda_base_process_order.arn
}

resource "aws_iam_role" "lambda_send_email" {
  name               = "lambda-send-email"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_send_email" {
  role       = aws_iam_role.lambda_send_email.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_send_email" {
  name   = "lambda-send-email-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_send_email" {
  role       = aws_iam_role.lambda_send_email.name
  policy_arn = aws_iam_policy.lambda_base_send_email.arn
}

resource "aws_iam_role" "lambda_resize_image" {
  name               = "lambda-resize-image"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_resize_image" {
  role       = aws_iam_role.lambda_resize_image.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_resize_image" {
  name   = "lambda-resize-image-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_resize_image" {
  role       = aws_iam_role.lambda_resize_image.name
  policy_arn = aws_iam_policy.lambda_base_resize_image.arn
}

resource "aws_iam_role" "lambda_validate_payment" {
  name               = "lambda-validate-payment"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_validate_payment" {
  role       = aws_iam_role.lambda_validate_payment.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_validate_payment" {
  name   = "lambda-validate-payment-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_validate_payment" {
  role       = aws_iam_role.lambda_validate_payment.name
  policy_arn = aws_iam_policy.lambda_base_validate_payment.arn
}

resource "aws_iam_role" "lambda_sync_inventory" {
  name               = "lambda-sync-inventory"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_sync_inventory" {
  role       = aws_iam_role.lambda_sync_inventory.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_sync_inventory" {
  name   = "lambda-sync-inventory-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_sync_inventory" {
  role       = aws_iam_role.lambda_sync_inventory.name
  policy_arn = aws_iam_policy.lambda_base_sync_inventory.arn
}

resource "aws_iam_role" "lambda_generate_report" {
  name               = "lambda-generate-report"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_generate_report" {
  role       = aws_iam_role.lambda_generate_report.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_generate_report" {
  name   = "lambda-generate-report-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_generate_report" {
  role       = aws_iam_role.lambda_generate_report.name
  policy_arn = aws_iam_policy.lambda_base_generate_report.arn
}

resource "aws_iam_role" "lambda_cleanup_sessions" {
  name               = "lambda-cleanup-sessions"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_cleanup_sessions" {
  role       = aws_iam_role.lambda_cleanup_sessions.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_cleanup_sessions" {
  name   = "lambda-cleanup-sessions-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_cleanup_sessions" {
  role       = aws_iam_role.lambda_cleanup_sessions.name
  policy_arn = aws_iam_policy.lambda_base_cleanup_sessions.arn
}

resource "aws_iam_role" "lambda_data_transformer" {
  name               = "lambda-data-transformer"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_data_transformer" {
  role       = aws_iam_role.lambda_data_transformer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_data_transformer" {
  name   = "lambda-data-transformer-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_data_transformer" {
  role       = aws_iam_role.lambda_data_transformer.name
  policy_arn = aws_iam_policy.lambda_base_data_transformer.arn
}

resource "aws_iam_role" "lambda_notification_sender" {
  name               = "lambda-notification-sender"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_notification_sender" {
  role       = aws_iam_role.lambda_notification_sender.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_notification_sender" {
  name   = "lambda-notification-sender-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_notification_sender" {
  role       = aws_iam_role.lambda_notification_sender.name
  policy_arn = aws_iam_policy.lambda_base_notification_sender.arn
}

resource "aws_iam_role" "lambda_cache_warmer" {
  name               = "lambda-cache-warmer"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_cache_warmer" {
  role       = aws_iam_role.lambda_cache_warmer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_cache_warmer" {
  name   = "lambda-cache-warmer-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_cache_warmer" {
  role       = aws_iam_role.lambda_cache_warmer.name
  policy_arn = aws_iam_policy.lambda_base_cache_warmer.arn
}

resource "aws_iam_role" "lambda_batch_processor" {
  name               = "lambda-batch-processor"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_batch_processor" {
  role       = aws_iam_role.lambda_batch_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_batch_processor" {
  name   = "lambda-batch-processor-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_batch_processor" {
  role       = aws_iam_role.lambda_batch_processor.name
  policy_arn = aws_iam_policy.lambda_base_batch_processor.arn
}

resource "aws_iam_role" "lambda_stream_consumer" {
  name               = "lambda-stream-consumer"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_stream_consumer" {
  role       = aws_iam_role.lambda_stream_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_stream_consumer" {
  name   = "lambda-stream-consumer-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_stream_consumer" {
  role       = aws_iam_role.lambda_stream_consumer.name
  policy_arn = aws_iam_policy.lambda_base_stream_consumer.arn
}

resource "aws_iam_role" "lambda_api_authorizer" {
  name               = "lambda-api-authorizer"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_api_authorizer" {
  role       = aws_iam_role.lambda_api_authorizer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_api_authorizer" {
  name   = "lambda-api-authorizer-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_api_authorizer" {
  role       = aws_iam_role.lambda_api_authorizer.name
  policy_arn = aws_iam_policy.lambda_base_api_authorizer.arn
}

resource "aws_iam_role" "lambda_migrate_data" {
  name               = "lambda-migrate-data"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_migrate_data" {
  role       = aws_iam_role.lambda_migrate_data.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_migrate_data" {
  name   = "lambda-migrate-data-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_migrate_data" {
  role       = aws_iam_role.lambda_migrate_data.name
  policy_arn = aws_iam_policy.lambda_base_migrate_data.arn
}

resource "aws_iam_role" "lambda_archive_records" {
  name               = "lambda-archive-records"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_archive_records" {
  role       = aws_iam_role.lambda_archive_records.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_policy" "lambda_base_archive_records" {
  name   = "lambda-archive-records-base"
  policy = local.lambda_base_policy
}
resource "aws_iam_role_policy_attachment" "lambda_base_archive_records" {
  role       = aws_iam_role.lambda_archive_records.name
  policy_arn = aws_iam_policy.lambda_base_archive_records.arn
}

# EC2 Instance Profile
resource "aws_iam_role" "ec2_instance" {
  name               = "ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# VPC Flow Logs Role
resource "aws_iam_role" "flow_logs" {
  name               = "vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json
}

resource "aws_iam_policy" "flow_logs" {
  name = "vpc-flow-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "flow_logs" {
  role       = aws_iam_role.flow_logs.name
  policy_arn = aws_iam_policy.flow_logs.arn
}

# CodeBuild Role
locals {
  codebuild_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "codebuild_api_gateway" {
  name               = "codebuild-api-gateway"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_api_gateway" {
  name   = "codebuild-api-gateway-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_api_gateway" {
  role       = aws_iam_role.codebuild_api_gateway.name
  policy_arn = aws_iam_policy.codebuild_api_gateway.arn
}

resource "aws_iam_role" "codebuild_user_service" {
  name               = "codebuild-user-service"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_user_service" {
  name   = "codebuild-user-service-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_user_service" {
  role       = aws_iam_role.codebuild_user_service.name
  policy_arn = aws_iam_policy.codebuild_user_service.arn
}

resource "aws_iam_role" "codebuild_order_service" {
  name               = "codebuild-order-service"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_order_service" {
  name   = "codebuild-order-service-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_order_service" {
  role       = aws_iam_role.codebuild_order_service.name
  policy_arn = aws_iam_policy.codebuild_order_service.arn
}

resource "aws_iam_role" "codebuild_payment_service" {
  name               = "codebuild-payment-service"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_payment_service" {
  name   = "codebuild-payment-service-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_payment_service" {
  role       = aws_iam_role.codebuild_payment_service.name
  policy_arn = aws_iam_policy.codebuild_payment_service.arn
}

resource "aws_iam_role" "codebuild_inventory_service" {
  name               = "codebuild-inventory-service"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_inventory_service" {
  name   = "codebuild-inventory-service-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_inventory_service" {
  role       = aws_iam_role.codebuild_inventory_service.name
  policy_arn = aws_iam_policy.codebuild_inventory_service.arn
}

resource "aws_iam_role" "codebuild_notification_service" {
  name               = "codebuild-notification-service"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_notification_service" {
  name   = "codebuild-notification-service-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_notification_service" {
  role       = aws_iam_role.codebuild_notification_service.name
  policy_arn = aws_iam_policy.codebuild_notification_service.arn
}

resource "aws_iam_role" "codebuild_catalog_service" {
  name               = "codebuild-catalog-service"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_catalog_service" {
  name   = "codebuild-catalog-service-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_catalog_service" {
  role       = aws_iam_role.codebuild_catalog_service.name
  policy_arn = aws_iam_policy.codebuild_catalog_service.arn
}

resource "aws_iam_role" "codebuild_search_service" {
  name               = "codebuild-search-service"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}
resource "aws_iam_policy" "codebuild_search_service" {
  name   = "codebuild-search-service-policy"
  policy = local.codebuild_policy
}
resource "aws_iam_role_policy_attachment" "codebuild_search_service" {
  role       = aws_iam_role.codebuild_search_service.name
  policy_arn = aws_iam_policy.codebuild_search_service.arn
}

# CodePipeline Role
resource "aws_iam_role" "codepipeline" {
  name               = "codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

resource "aws_iam_policy" "codepipeline" {
  name = "codepipeline-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

# EKS Cluster Role
resource "aws_iam_role" "eks_cluster" {
  for_each           = toset(["prod", "staging"])
  name               = "${each.key}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  for_each   = toset(["prod", "staging"])
  role       = aws_iam_role.eks_cluster[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Node Role
resource "aws_iam_role" "eks_node" {
  for_each           = toset(["prod", "staging"])
  name               = "${each.key}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_node_worker" {
  for_each   = toset(["prod", "staging"])
  role       = aws_iam_role.eks_node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr" {
  for_each   = toset(["prod", "staging"])
  role       = aws_iam_role.eks_node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni" {
  for_each   = toset(["prod", "staging"])
  role       = aws_iam_role.eks_node[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Firehose Role
resource "aws_iam_role" "firehose" {
  name               = "firehose-delivery-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_policy" "firehose" {
  name = "firehose-delivery-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:DescribeStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

# Step Functions Role
resource "aws_iam_role" "step_functions" {
  name               = "step-functions-role"
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role.json
}

resource "aws_iam_policy" "step_functions" {
  name = "step-functions-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks",
          "sqs:SendMessage",
          "sns:Publish",
          "states:StartExecution",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions" {
  role       = aws_iam_role.step_functions.name
  policy_arn = aws_iam_policy.step_functions.arn
}

# EventBridge Role
resource "aws_iam_role" "eventbridge" {
  name               = "eventbridge-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
}

resource "aws_iam_policy" "eventbridge" {
  name = "eventbridge-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "sqs:SendMessage",
          "sns:Publish",
          "states:StartExecution"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eventbridge.arn
}

# IAM Users (service accounts)
resource "aws_iam_user" "service_accounts" {
  for_each = toset([
    "ci-deployment", "monitoring-agent", "backup-agent",
    "datadog-integration", "terraform-automation", "analytics-reader",
    "audit-exporter", "s3-replication-agent"
  ])
  name = each.key
}

resource "aws_iam_access_key" "service_accounts" {
  for_each = toset([
    "ci-deployment", "monitoring-agent", "backup-agent",
    "datadog-integration", "terraform-automation", "analytics-reader",
    "audit-exporter", "s3-replication-agent"
  ])
  user = aws_iam_user.service_accounts[each.key].name
}

# IAM Groups
resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_group" "ops" {
  name = "ops"
}

resource "aws_iam_group" "read_only" {
  name = "read-only"
}

resource "aws_iam_group_policy_attachment" "developers_poweruser" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_group_policy_attachment" "ops_admin" {
  group      = aws_iam_group.ops.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "read_only" {
  group      = aws_iam_group.read_only.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Cognito
resource "aws_cognito_user_pool" "main" {
  for_each = toset(var.environments)
  name     = "${each.key}-user-pool"

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "given_name"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }
}

resource "aws_cognito_user_pool_client" "web" {
  for_each        = toset(var.environments)
  name            = "${each.key}-web-client"
  user_pool_id    = aws_cognito_user_pool.main[each.key].id
  generate_secret = false

  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = ["https://example.com/callback"]
  logout_urls                          = ["https://example.com/logout"]
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_pool_client" "mobile" {
  for_each        = toset(var.environments)
  name            = "${each.key}-mobile-client"
  user_pool_id    = aws_cognito_user_pool.main[each.key].id
  generate_secret = true

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = ["myapp://callback"]
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_identity_pool" "main" {
  for_each                         = toset(var.environments)
  identity_pool_name               = "${each.key}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.web[each.key].id
    provider_name           = aws_cognito_user_pool.main[each.key].endpoint
    server_side_token_check = false
  }
}
