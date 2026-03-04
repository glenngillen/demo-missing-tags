# ============================================================
# Application Load Balancers — Public (1 per env)
# ============================================================

resource "aws_lb" "main" {
  for_each           = toset(var.environments)
  name               = "${each.key}-main-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_public[each.key].id]

  subnets = [
    aws_subnet.public["${each.key}-0"].id,
    aws_subnet.public["${each.key}-1"].id,
    aws_subnet.public["${each.key}-2"].id,
  ]

  enable_deletion_protection = each.key == "prod"
  enable_http2               = true
  idle_timeout               = 60

  access_logs {
    bucket  = aws_s3_bucket.infra["access-logs"].id
    prefix  = "${each.key}/alb-main"
    enabled = true
  }
}

resource "aws_lb_listener" "main_https" {
  for_each          = toset(var.environments)
  load_balancer_arn = aws_lb.main[each.key].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web[each.key].arn
  }
}

resource "aws_lb_listener" "main_http_redirect" {
  for_each          = toset(var.environments)
  load_balancer_arn = aws_lb.main[each.key].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ============================================================
# Application Load Balancers — API (1 per env)
# ============================================================

resource "aws_lb" "api" {
  for_each           = toset(var.environments)
  name               = "${each.key}-api-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_public[each.key].id]

  subnets = [
    aws_subnet.public["${each.key}-0"].id,
    aws_subnet.public["${each.key}-1"].id,
    aws_subnet.public["${each.key}-2"].id,
  ]

  enable_deletion_protection = each.key == "prod"
  enable_http2               = true

  access_logs {
    bucket  = aws_s3_bucket.infra["access-logs"].id
    prefix  = "${each.key}/alb-api"
    enabled = true
  }
}

resource "aws_lb_listener" "api_https" {
  for_each          = toset(var.environments)
  load_balancer_arn = aws_lb.api[each.key].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api[each.key].arn
  }
}

resource "aws_lb_listener" "api_http_redirect" {
  for_each          = toset(var.environments)
  load_balancer_arn = aws_lb.api[each.key].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ============================================================
# Internal NLB for microservice mesh (1 per env)
# ============================================================

resource "aws_lb" "internal" {
  for_each           = toset(var.environments)
  name               = "${each.key}-internal-nlb"
  internal           = true
  load_balancer_type = "network"

  subnets = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]
}

resource "aws_lb_listener" "internal" {
  for_each          = toset(var.environments)
  load_balancer_arn = aws_lb.internal[each.key].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal[each.key].arn
  }
}

# ============================================================
# Target Groups
# ============================================================

resource "aws_lb_target_group" "web" {
  for_each    = toset(var.environments)
  name        = "${each.key}-web-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main[each.key].id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30
}

resource "aws_lb_target_group" "api" {
  for_each    = toset(var.environments)
  name        = "${each.key}-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main[each.key].id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "internal" {
  for_each    = toset(var.environments)
  name        = "${each.key}-internal-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main[each.key].id
  target_type = "ip"

  health_check {
    enabled  = true
    protocol = "TCP"
    port     = "traffic-port"
    interval = 30
  }
}

# Per-microservice target groups
resource "aws_lb_target_group" "microservices" {
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

  name        = "${each.value.env}-${substr(each.value.svc, 0, min(25, length(each.value.svc)))}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main[each.value.env].id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30
}

# ALB Listener Rules for microservices
resource "aws_lb_listener_rule" "microservices" {
  for_each = {
    for idx, svc in var.microservices : svc => {
      svc      = svc
      priority = idx + 1
    }
  }

  listener_arn = aws_lb_listener.api_https["prod"].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.microservices["prod-${each.value.svc}"].arn
  }

  condition {
    path_pattern {
      values = ["/api/${each.value.svc}/*"]
    }
  }
}

# ============================================================
# EC2 — Bastion Hosts
# ============================================================

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  for_each               = toset(var.environments)
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public["${each.key}-0"].id
  vpc_security_group_ids = [aws_security_group.ec2_bastion[each.key].id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
  EOF
  )
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0placeholder deployer@example.com"
}

# ============================================================
# EC2 — Worker Nodes (standalone, for batch jobs)
# ============================================================

resource "aws_launch_template" "worker" {
  for_each      = toset(var.environments)
  name          = "${each.key}-worker-lt"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_types[each.key]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  vpc_security_group_ids = [aws_security_group.ecs_tasks[each.key].id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.rds.arn
    }
  }

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
  EOF
  )
}

resource "aws_autoscaling_group" "worker" {
  for_each         = toset(var.environments)
  name             = "${each.key}-worker-asg"
  min_size         = each.key == "prod" ? 2 : 1
  max_size         = each.key == "prod" ? 20 : 5
  desired_capacity = each.key == "prod" ? 4 : 1

  vpc_zone_identifier = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]

  launch_template {
    id      = aws_launch_template.worker[each.key].id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  termination_policies = ["OldestLaunchTemplate", "OldestInstance"]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

resource "aws_autoscaling_policy" "worker_scale_up" {
  for_each               = toset(var.environments)
  name                   = "${each.key}-worker-scale-up"
  autoscaling_group_name = aws_autoscaling_group.worker[each.key].name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 2
  cooldown               = 300
}

resource "aws_autoscaling_policy" "worker_scale_down" {
  for_each               = toset(var.environments)
  name                   = "${each.key}-worker-scale-down"
  autoscaling_group_name = aws_autoscaling_group.worker[each.key].name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 600
}

resource "aws_autoscaling_policy" "worker_cpu" {
  for_each               = toset(var.environments)
  name                   = "${each.key}-worker-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.worker[each.key].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# ============================================================
# EC2 — Dedicated App Servers (non-containerized legacy)
# ============================================================

resource "aws_launch_template" "app_server" {
  for_each      = toset(["prod", "staging"])
  name          = "${each.key}-app-server-lt"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_types[each.key]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  vpc_security_group_ids = [aws_security_group.ecs_tasks[each.key].id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 200
      volume_type           = "gp3"
      iops                  = 6000
      throughput            = 250
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.rds.arn
    }
  }

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

resource "aws_autoscaling_group" "app_server" {
  for_each         = toset(["prod", "staging"])
  name             = "${each.key}-app-server-asg"
  min_size         = each.key == "prod" ? 3 : 1
  max_size         = each.key == "prod" ? 30 : 5
  desired_capacity = each.key == "prod" ? 6 : 2

  vpc_zone_identifier = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]

  launch_template {
    id      = aws_launch_template.app_server[each.key].id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [aws_lb_target_group.web[each.key].arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 70
    }
  }
}

resource "aws_autoscaling_policy" "app_server_cpu" {
  for_each               = toset(["prod", "staging"])
  name                   = "${each.key}-app-server-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.app_server[each.key].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 65.0
  }
}

resource "aws_autoscaling_policy" "app_server_requests" {
  for_each               = toset(["prod", "staging"])
  name                   = "${each.key}-app-server-requests-policy"
  autoscaling_group_name = aws_autoscaling_group.app_server[each.key].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main[each.key].arn_suffix}/${aws_lb_target_group.web[each.key].arn_suffix}"
    }
    target_value = 1000.0
  }
}

# Scheduled scaling for prod
resource "aws_autoscaling_schedule" "app_server_scale_up" {
  scheduled_action_name  = "prod-app-server-morning-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app_server["prod"].name
  min_size               = 6
  max_size               = 30
  desired_capacity       = 10
  recurrence             = "0 8 * * MON-FRI"
}

resource "aws_autoscaling_schedule" "app_server_scale_down" {
  scheduled_action_name  = "prod-app-server-night-scale-down"
  autoscaling_group_name = aws_autoscaling_group.app_server["prod"].name
  min_size               = 3
  max_size               = 30
  desired_capacity       = 6
  recurrence             = "0 20 * * MON-FRI"
}
