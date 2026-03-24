# ============================================================
# ECR Repositories
# ============================================================

locals {
  ecr_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_repository" "api_gateway" {
  name                 = "api-gateway"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }
}
resource "aws_ecr_lifecycle_policy" "api_gateway" {
  repository = aws_ecr_repository.api_gateway.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "user_service" {
  name                 = "user-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }
}
resource "aws_ecr_lifecycle_policy" "user_service" {
  repository = aws_ecr_repository.user_service.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "order_service" {
  name                 = "order-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }
}
resource "aws_ecr_lifecycle_policy" "order_service" {
  repository = aws_ecr_repository.order_service.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "payment_service" {
  name                 = "payment-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }
}
resource "aws_ecr_lifecycle_policy" "payment_service" {
  repository = aws_ecr_repository.payment_service.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "inventory_service" {
  name                 = "inventory-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }
}
resource "aws_ecr_lifecycle_policy" "inventory_service" {
  repository = aws_ecr_repository.inventory_service.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "notification_service" {
  name                 = "notification-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }

}
resource "aws_ecr_lifecycle_policy" "notification_service" {
  repository = aws_ecr_repository.notification_service.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "catalog_service" {
  name                 = "catalog-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }
}
resource "aws_ecr_lifecycle_policy" "catalog_service" {
  repository = aws_ecr_repository.catalog_service.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "search_service" {
  name                 = "search-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key = aws_kms_key.rds.arn
  }
}
resource "aws_ecr_lifecycle_policy" "search_service" {
  repository = aws_ecr_repository.search_service.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_repository" "base_images" {
  for_each             = toset(["node-base", "python-base", "java-base", "nginx-base"])
  name                 = "base/${each.key}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ============================================================
# ECS Clusters
# ============================================================

resource "aws_ecs_cluster" "main" {
  for_each = toset(var.environments)
  name     = "${each.key}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.cloudwatch.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_exec[each.key].name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  for_each     = toset(var.environments)
  cluster_name = aws_ecs_cluster.main[each.key].name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }
}

# ============================================================
# ECS Task Definitions (one per microservice)
# ============================================================

locals {
  ecs_xray_sidecar = {
    name      = "xray-daemon"
    image     = "amazon/aws-xray-daemon"
    essential = false
    cpu       = 32
    memory    = 256
    portMappings = [{ containerPort = 2000, protocol = "udp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/xray-daemon"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "xray"
      }
    }
  }
  ecs_common_secrets = [
    { name = "DB_PASSWORD", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/database/password" },
    { name = "JWT_SECRET", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/app/jwt_secret" }
  ]
}

resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "api-gateway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_api_gateway.arn
  container_definitions = jsonencode([
    {
      name         = "api-gateway"
      image        = "${aws_ecr_repository.api_gateway.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "api-gateway" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/api-gateway", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

resource "aws_ecs_task_definition" "user_service" {
  family                   = "user-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_user_service.arn
  container_definitions = jsonencode([
    {
      name         = "user-service"
      image        = "${aws_ecr_repository.user_service.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "user-service" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/user-service", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

resource "aws_ecs_task_definition" "order_service" {
  family                   = "order-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_order_service.arn
  container_definitions = jsonencode([
    {
      name         = "order-service"
      image        = "${aws_ecr_repository.order_service.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "order-service" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/order-service", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

resource "aws_ecs_task_definition" "payment_service" {
  family                   = "payment-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_payment_service.arn
  container_definitions = jsonencode([
    {
      name         = "payment-service"
      image        = "${aws_ecr_repository.payment_service.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "payment-service" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/payment-service", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

resource "aws_ecs_task_definition" "inventory_service" {
  family                   = "inventory-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_inventory_service.arn
  container_definitions = jsonencode([
    {
      name         = "inventory-service"
      image        = "${aws_ecr_repository.inventory_service.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "inventory-service" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/inventory-service", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

resource "aws_ecs_task_definition" "notification_service" {
  family                   = "notification-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_notification_service.arn
  container_definitions = jsonencode([
    {
      name         = "notification-service"
      image        = "${aws_ecr_repository.notification_service.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "notification-service" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/notification-service", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

resource "aws_ecs_task_definition" "catalog_service" {
  family                   = "catalog-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_catalog_service.arn
  container_definitions = jsonencode([
    {
      name         = "catalog-service"
      image        = "${aws_ecr_repository.catalog_service.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "catalog-service" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/catalog-service", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

resource "aws_ecs_task_definition" "search_service" {
  family                   = "search-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn            = aws_iam_role.ecs_task_search_service.arn
  container_definitions = jsonencode([
    {
      name         = "search-service"
      image        = "${aws_ecr_repository.search_service.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
      environment  = [{ name = "SERVICE_NAME", value = "search-service" }, { name = "LOG_LEVEL", value = "info" }, { name = "PORT", value = "8080" }]
      secrets      = local.ecs_common_secrets
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/search-service", "awslogs-region" = "us-east-1", "awslogs-stream-prefix" = "ecs" } }
      healthCheck  = { command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"], interval = 30, timeout = 5, retries = 3, startPeriod = 60 }
      ulimits      = [{ name = "nofile", softLimit = 65536, hardLimit = 65536 }]
    },
    local.ecs_xray_sidecar
  ])
}

# ============================================================
# ECS Services (per microservice per environment)
# ============================================================

resource "aws_ecs_service" "api_gateway" {
  for_each        = toset(var.environments)
  name            = "api-gateway"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api_gateway[each.key].arn
    container_name = "api-gateway"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_ecs_service" "user_service" {
  for_each        = toset(var.environments)
  name            = "user-service"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.user_service[each.key].arn
    container_name = "user-service"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_ecs_service" "order_service" {
  for_each        = toset(var.environments)
  name            = "order-service"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.order_service[each.key].arn
    container_name = "order-service"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_ecs_service" "payment_service" {
  for_each        = toset(var.environments)
  name            = "payment-service"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.payment_service.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.payment_service[each.key].arn
    container_name = "payment-service"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_ecs_service" "inventory_service" {
  for_each        = toset(var.environments)
  name            = "inventory-service"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.inventory_service.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.inventory_service[each.key].arn
    container_name = "inventory-service"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_ecs_service" "notification_service" {
  for_each        = toset(var.environments)
  name            = "notification-service"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.notification_service.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.notification_service[each.key].arn
    container_name = "notification-service"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_ecs_service" "catalog_service" {
  for_each        = toset(var.environments)
  name            = "catalog-service"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.catalog_service.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.catalog_service[each.key].arn
    container_name = "catalog-service"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

resource "aws_ecs_service" "search_service" {
  for_each        = toset(var.environments)
  name            = "search-service"
  cluster         = aws_ecs_cluster.main[each.key].id
  task_definition = aws_ecs_task_definition.search_service.arn
  desired_count   = each.key == "prod" ? 3 : 1
  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight = 1
  }
  network_configuration {
    subnets          = [aws_subnet.private["${each.key}-0"].id, aws_subnet.private["${each.key}-1"].id, aws_subnet.private["${each.key}-2"].id]
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.search_service[each.key].arn
    container_name = "search-service"
    container_port = 8080
  }
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  deployment_controller { type = "ECS" }
  health_check_grace_period_seconds = 120
  lifecycle { ignore_changes = [desired_count] }
}

# ============================================================
# ECS Auto Scaling
# ============================================================

resource "aws_appautoscaling_target" "ecs_api_gateway" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/api-gateway"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.api_gateway]
}
resource "aws_appautoscaling_policy" "ecs_cpu_api_gateway" {
  name = "api-gateway-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_api_gateway.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_api_gateway.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_api_gateway.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_api_gateway" {
  name = "api-gateway-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_api_gateway.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_api_gateway.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_api_gateway.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "ecs_user_service" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/user-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.user_service]
}
resource "aws_appautoscaling_policy" "ecs_cpu_user_service" {
  name = "user-service-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_user_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_user_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_user_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_user_service" {
  name = "user-service-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_user_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_user_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_user_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "ecs_order_service" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/order-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.order_service]
}
resource "aws_appautoscaling_policy" "ecs_cpu_order_service" {
  name = "order-service-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_order_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_order_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_order_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_order_service" {
  name = "order-service-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_order_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_order_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_order_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "ecs_payment_service" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/payment-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.payment_service]
}
resource "aws_appautoscaling_policy" "ecs_cpu_payment_service" {
  name = "payment-service-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_payment_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_payment_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_payment_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_payment_service" {
  name = "payment-service-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_payment_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_payment_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_payment_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "ecs_inventory_service" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/inventory-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.inventory_service]
}
resource "aws_appautoscaling_policy" "ecs_cpu_inventory_service" {
  name = "inventory-service-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_inventory_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_inventory_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_inventory_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_inventory_service" {
  name = "inventory-service-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_inventory_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_inventory_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_inventory_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "ecs_notification_service" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/notification-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.notification_service]
}
resource "aws_appautoscaling_policy" "ecs_cpu_notification_service" {
  name = "notification-service-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_notification_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_notification_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_notification_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_notification_service" {
  name = "notification-service-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_notification_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_notification_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_notification_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "ecs_catalog_service" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/catalog-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.catalog_service]
}
resource "aws_appautoscaling_policy" "ecs_cpu_catalog_service" {
  name = "catalog-service-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_catalog_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_catalog_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_catalog_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_catalog_service" {
  name = "catalog-service-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_catalog_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_catalog_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_catalog_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "ecs_search_service" {
  max_capacity = 20
  min_capacity = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/search-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.search_service]
}
resource "aws_appautoscaling_policy" "ecs_cpu_search_service" {
  name = "search-service-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_search_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_search_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_search_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_policy" "ecs_memory_search_service" {
  name = "search-service-memory-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_search_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_search_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_search_service.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
    target_value = 80.0
    scale_in_cooldown = 300
    scale_out_cooldown = 60
  }
}

# ============================================================
# EKS Clusters
# ============================================================

resource "aws_eks_cluster" "main" {
  for_each = toset(["prod", "staging"])
  name     = "${each.key}-eks"
  role_arn = aws_iam_role.eks_cluster[each.key].arn
  version  = "1.28"

  vpc_config {
    subnet_ids = [
      aws_subnet.private["${each.key}-0"].id,
      aws_subnet.private["${each.key}-1"].id,
      aws_subnet.private["${each.key}-2"].id,
    ]
    security_group_ids      = [aws_security_group.eks_cluster[each.key].id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["10.0.0.0/8"]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.secrets.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster
  ]
}

resource "aws_eks_node_group" "general" {
  for_each        = toset(["prod", "staging"])
  cluster_name    = aws_eks_cluster.main[each.key].name
  node_group_name = "${each.key}-general"
  node_role_arn   = aws_iam_role.eks_node[each.key].arn
  instance_types  = [var.instance_types[each.key]]

  subnet_ids = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]

  scaling_config {
    desired_size = each.key == "prod" ? 4 : 2
    max_size     = each.key == "prod" ? 20 : 6
    min_size     = each.key == "prod" ? 2 : 1
  }

  update_config {
    max_unavailable = 1
  }

  disk_size = 100

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker,
    aws_iam_role_policy_attachment.eks_node_ecr,
    aws_iam_role_policy_attachment.eks_node_cni,
  ]
}

resource "aws_eks_node_group" "memory_optimized" {
  cluster_name    = aws_eks_cluster.main["prod"].name
  node_group_name = "prod-memory-optimized"
  node_role_arn   = aws_iam_role.eks_node["prod"].arn
  instance_types  = ["r5.2xlarge"]

  subnet_ids = [
    aws_subnet.private["prod-0"].id,
    aws_subnet.private["prod-1"].id,
    aws_subnet.private["prod-2"].id,
  ]

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  disk_size = 200

  taint {
    key    = "workload"
    value  = "memory-intensive"
    effect = "NO_SCHEDULE"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker,
    aws_iam_role_policy_attachment.eks_node_ecr,
    aws_iam_role_policy_attachment.eks_node_cni,
  ]
}

resource "aws_eks_node_group" "compute_optimized" {
  cluster_name    = aws_eks_cluster.main["prod"].name
  node_group_name = "prod-compute-optimized"
  node_role_arn   = aws_iam_role.eks_node["prod"].arn
  instance_types  = ["c5.4xlarge"]

  subnet_ids = [
    aws_subnet.private["prod-0"].id,
    aws_subnet.private["prod-1"].id,
    aws_subnet.private["prod-2"].id,
  ]

  scaling_config {
    desired_size = 2
    max_size     = 15
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  disk_size = 100

  taint {
    key    = "workload"
    value  = "compute-intensive"
    effect = "NO_SCHEDULE"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker,
    aws_iam_role_policy_attachment.eks_node_ecr,
    aws_iam_role_policy_attachment.eks_node_cni,
  ]
}

resource "aws_eks_addon" "coredns" {
  for_each     = toset(["prod", "staging"])
  cluster_name = aws_eks_cluster.main[each.key].name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  for_each     = toset(["prod", "staging"])
  cluster_name = aws_eks_cluster.main[each.key].name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
  for_each     = toset(["prod", "staging"])
  cluster_name = aws_eks_cluster.main[each.key].name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  for_each     = toset(["prod", "staging"])
  cluster_name = aws_eks_cluster.main[each.key].name
  addon_name   = "aws-ebs-csi-driver"
}
