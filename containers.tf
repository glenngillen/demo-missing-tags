# ============================================================
# ECR Repositories
# ============================================================

resource "aws_ecr_repository" "microservices" {
  for_each             = toset(var.microservices)
  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.rds.arn
  }
}

resource "aws_ecr_lifecycle_policy" "microservices" {
  for_each   = toset(var.microservices)
  repository = aws_ecr_repository.microservices[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
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

resource "aws_ecs_task_definition" "microservices" {
  for_each                 = toset(var.microservices)
  family                   = each.key
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048

  execution_role_arn = aws_iam_role.ecs_execution["prod"].arn
  task_role_arn      = aws_iam_role.ecs_task[each.key].arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = "${aws_ecr_repository.microservices[each.key].repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "SERVICE_NAME", value = each.key },
        { name = "LOG_LEVEL", value = "info" },
        { name = "PORT", value = "8080" }
      ]

      secrets = [
        { name = "DB_PASSWORD", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/database/password" },
        { name = "JWT_SECRET", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/prod/app/jwt_secret" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${each.key}"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      ulimits = [
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]
    },
    {
      name      = "xray-daemon"
      image     = "amazon/aws-xray-daemon"
      essential = false
      cpu       = 32
      memory    = 256

      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/xray-daemon"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "xray"
        }
      }
    }
  ])
}

# ============================================================
# ECS Services (per microservice per environment)
# ============================================================

resource "aws_ecs_service" "microservices" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for svc in var.microservices : {
          key = "${env}-${svc}"
          env = env
          svc = svc
        }
      ]
    ]) : pair.key => pair
  }

  name            = "${each.value.svc}"
  cluster         = aws_ecs_cluster.main[each.value.env].id
  task_definition = aws_ecs_task_definition.microservices[each.value.svc].arn
  desired_count   = each.value.env == "prod" ? 3 : 1

  capacity_provider_strategy {
    capacity_provider = each.value.env == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets = [
      aws_subnet.private["${each.value.env}-0"].id,
      aws_subnet.private["${each.value.env}-1"].id,
      aws_subnet.private["${each.value.env}-2"].id,
    ]
    security_groups  = [aws_security_group.ecs_tasks[each.value.env].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.microservices["${each.value.env}-${each.value.svc}"].arn
    container_name   = each.value.svc
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  health_check_grace_period_seconds = 120

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ============================================================
# ECS Auto Scaling
# ============================================================

resource "aws_appautoscaling_target" "ecs" {
  for_each           = toset(var.microservices)
  max_capacity       = 20
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main["prod"].name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.microservices]
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  for_each           = toset(var.microservices)
  name               = "${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "ecs_memory" {
  for_each           = toset(var.microservices)
  name               = "${each.key}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
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
