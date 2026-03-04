# ============================================================
# CodeBuild Projects
# ============================================================

resource "aws_codebuild_project" "build" {
  for_each      = toset(var.microservices)
  name          = "${each.key}-build"
  description   = "Build and test ${each.key}"
  build_timeout = 30
  service_role  = aws_iam_role.codebuild[each.key].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.infra["codebuild-cache"].id}/${each.key}"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ECR_REPO_URI"
      value = aws_ecr_repository.microservices[each.key].repository_url
    }

    environment_variable {
      name  = "SERVICE_NAME"
      value = each.key
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
  }

  vpc_config {
    vpc_id = aws_vpc.main["prod"].id

    subnets = [
      aws_subnet.private["prod-0"].id,
      aws_subnet.private["prod-1"].id,
    ]

    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        pre_build:
          commands:
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
            - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
            - IMAGE_TAG=$${COMMIT_HASH:=latest}
        build:
          commands:
            - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .
            - docker push $ECR_REPO_URI:latest
            - docker push $ECR_REPO_URI:$IMAGE_TAG
            - printf '[{"name":"${each.key}","imageUri":"%s"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json
        post_build:
          commands:
            - echo Build completed
      artifacts:
        files: imagedefinitions.json
    EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild[each.key].name
      stream_name = "build"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.infra["codebuild-cache"].id}/${each.key}/logs"
    }
  }
}

resource "aws_codebuild_project" "test" {
  for_each      = toset(var.microservices)
  name          = "${each.key}-test"
  description   = "Integration tests for ${each.key}"
  build_timeout = 20
  service_role  = aws_iam_role.codebuild[each.key].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "SERVICE_NAME"
      value = each.key
    }

    environment_variable {
      name       = "DB_CONNECTION"
      value      = "/${each.key}/database/connection"
      type       = "PARAMETER_STORE"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOF
      version: 0.2
      phases:
        install:
          commands:
            - npm install
        build:
          commands:
            - npm run test:unit
            - npm run test:integration
      reports:
        test-results:
          files:
            - 'test-results/**/*.xml'
    EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild[each.key].name
      stream_name = "test"
    }
  }
}

resource "aws_codebuild_project" "security_scan" {
  name          = "security-scan"
  description   = "SAST and dependency scanning"
  build_timeout = 15
  service_role  = aws_iam_role.codebuild[var.microservices[0]].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/myorg/myapp"
    git_clone_depth = 1
    buildspec       = <<-EOF
      version: 0.2
      phases:
        install:
          commands:
            - npm install -g snyk
        build:
          commands:
            - snyk test --all-projects
            - snyk iac test --severity-threshold=high
    EOF
  }
}

# ============================================================
# CodePipeline (one per microservice)
# ============================================================

resource "aws_codepipeline" "main" {
  for_each = toset(var.microservices)
  name     = "${each.key}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.s3.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "myorg/${each.key}"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "UnitTest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["test_output"]

      configuration = {
        ProjectName = aws_codebuild_project.test[each.key].name
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAndPush"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
      }
    }
  }

  stage {
    name = "DeployStaging"

    action {
      name            = "DeployToStaging"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main["staging"].name
        ServiceName = each.key
        FileName    = "imagedefinitions.json"
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.main["deployment-events"].arn
        CustomData      = "Please verify staging deployment of ${each.key} before approving production"
      }
    }
  }

  stage {
    name = "DeployProd"

    action {
      name            = "DeployToProduction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName       = aws_ecs_cluster.main["prod"].name
        ServiceName       = each.key
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = "15"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

# ============================================================
# CodeDeploy (for EC2 blue/green deployments)
# ============================================================

resource "aws_codedeploy_app" "main" {
  name             = "main-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "main" {
  for_each               = toset(["prod", "staging"])
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = "${each.key}-deployment-group"
  service_role_arn       = aws_iam_role.codepipeline.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = aws_ecs_cluster.main[each.key].name
    service_name = var.microservices[0]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.main_https[each.key].arn]
      }

      target_group {
        name = aws_lb_target_group.web[each.key].name
      }

      target_group {
        name = aws_lb_target_group.api[each.key].name
      }
    }
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
}

# ============================================================
# AWS Config
# ============================================================

resource "aws_config_configuration_recorder" "main" {
  name     = "main-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "main-config-channel"
  s3_bucket_name = aws_s3_bucket.infra["config-snapshots"].id

  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_iam_role" "config" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_s3_bucket" "infra" {
  for_each = toset(["config-snapshots"])
  bucket   = "mycompany-infra-${each.key}-${random_id.suffix.hex}"
}

# Config Rules
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encrypted" {
  name = "rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_public_access" {
  name = "s3-bucket-public-access-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "mfa_enabled" {
  name = "mfa-enabled-for-iam-console-access"

  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "vpc-flow-logs-enabled"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}
