# ============================================================
# CodeBuild Projects
# ============================================================

locals {
  codebuild_test_buildspec = <<-EOF
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
  codebuild_vpc_config = {
    vpc_id             = aws_vpc.main["prod"].id
    subnets            = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }
}

resource "aws_codebuild_project" "build_api_gateway" {
  name = "api-gateway-build"; description = "Build api-gateway"; build_timeout = 30
  service_role = aws_iam_role.codebuild_api_gateway.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/api-gateway" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.api_gateway.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "api-gateway" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"api-gateway\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_api_gateway.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/api-gateway/logs" } }
}
resource "aws_codebuild_project" "test_api_gateway" {
  name = "api-gateway-test"; description = "Tests for api-gateway"; build_timeout = 20
  service_role = aws_iam_role.codebuild_api_gateway.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "api-gateway" }
    environment_variable { name = "DB_CONNECTION"; value = "/api-gateway/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_api_gateway.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "build_user_service" {
  name = "user-service-build"; description = "Build user-service"; build_timeout = 30
  service_role = aws_iam_role.codebuild_user_service.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/user-service" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.user_service.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "user-service" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"user-service\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_user_service.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/user-service/logs" } }
}
resource "aws_codebuild_project" "test_user_service" {
  name = "user-service-test"; description = "Tests for user-service"; build_timeout = 20
  service_role = aws_iam_role.codebuild_user_service.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "user-service" }
    environment_variable { name = "DB_CONNECTION"; value = "/user-service/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_user_service.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "build_order_service" {
  name = "order-service-build"; description = "Build order-service"; build_timeout = 30
  service_role = aws_iam_role.codebuild_order_service.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/order-service" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.order_service.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "order-service" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"order-service\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_order_service.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/order-service/logs" } }
}
resource "aws_codebuild_project" "test_order_service" {
  name = "order-service-test"; description = "Tests for order-service"; build_timeout = 20
  service_role = aws_iam_role.codebuild_order_service.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "order-service" }
    environment_variable { name = "DB_CONNECTION"; value = "/order-service/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_order_service.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "build_payment_service" {
  name = "payment-service-build"; description = "Build payment-service"; build_timeout = 30
  service_role = aws_iam_role.codebuild_payment_service.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/payment-service" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.payment_service.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "payment-service" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"payment-service\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_payment_service.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/payment-service/logs" } }
}
resource "aws_codebuild_project" "test_payment_service" {
  name = "payment-service-test"; description = "Tests for payment-service"; build_timeout = 20
  service_role = aws_iam_role.codebuild_payment_service.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "payment-service" }
    environment_variable { name = "DB_CONNECTION"; value = "/payment-service/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_payment_service.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "build_inventory_service" {
  name = "inventory-service-build"; description = "Build inventory-service"; build_timeout = 30
  service_role = aws_iam_role.codebuild_inventory_service.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/inventory-service" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.inventory_service.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "inventory-service" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"inventory-service\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_inventory_service.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/inventory-service/logs" } }
}
resource "aws_codebuild_project" "test_inventory_service" {
  name = "inventory-service-test"; description = "Tests for inventory-service"; build_timeout = 20
  service_role = aws_iam_role.codebuild_inventory_service.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "inventory-service" }
    environment_variable { name = "DB_CONNECTION"; value = "/inventory-service/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_inventory_service.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "build_notification_service" {
  name = "notification-service-build"; description = "Build notification-service"; build_timeout = 30
  service_role = aws_iam_role.codebuild_notification_service.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/notification-service" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.notification_service.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "notification-service" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"notification-service\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_notification_service.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/notification-service/logs" } }
}
resource "aws_codebuild_project" "test_notification_service" {
  name = "notification-service-test"; description = "Tests for notification-service"; build_timeout = 20
  service_role = aws_iam_role.codebuild_notification_service.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "notification-service" }
    environment_variable { name = "DB_CONNECTION"; value = "/notification-service/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_notification_service.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "build_catalog_service" {
  name = "catalog-service-build"; description = "Build catalog-service"; build_timeout = 30
  service_role = aws_iam_role.codebuild_catalog_service.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/catalog-service" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.catalog_service.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "catalog-service" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"catalog-service\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_catalog_service.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/catalog-service/logs" } }
}
resource "aws_codebuild_project" "test_catalog_service" {
  name = "catalog-service-test"; description = "Tests for catalog-service"; build_timeout = 20
  service_role = aws_iam_role.codebuild_catalog_service.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "catalog-service" }
    environment_variable { name = "DB_CONNECTION"; value = "/catalog-service/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_catalog_service.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "build_search_service" {
  name = "search-service-build"; description = "Build search-service"; build_timeout = 30
  service_role = aws_iam_role.codebuild_search_service.arn
  artifacts { type = "CODEPIPELINE" }
  cache { type = "S3"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/search-service" }
  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = true
    environment_variable { name = "ECR_REPO_URI"; value = aws_ecr_repository.search_service.repository_url }
    environment_variable { name = "SERVICE_NAME"; value = "search-service" }
    environment_variable { name = "AWS_REGION"; value = var.aws_region }
  }
  dynamic "vpc_config" { for_each = [local.codebuild_vpc_config]; content { vpc_id = vpc_config.value.vpc_id; subnets = vpc_config.value.subnets; security_group_ids = vpc_config.value.security_group_ids } }
  source { type = "CODEPIPELINE"; buildspec = "version: 0.2\nphases:\n  pre_build:\n    commands:\n      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI\n      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)\n      - IMAGE_TAG=$${COMMIT_HASH:=latest}\n  build:\n    commands:\n      - docker build -t $ECR_REPO_URI:latest -t $ECR_REPO_URI:$IMAGE_TAG .\n      - docker push $ECR_REPO_URI:latest\n      - docker push $ECR_REPO_URI:$IMAGE_TAG\n      - printf '[{\"name\":\"search-service\",\"imageUri\":\"%s\"}]' $ECR_REPO_URI:$IMAGE_TAG > imagedefinitions.json\n  post_build:\n    commands:\n      - echo Build completed\nartifacts:\n  files: imagedefinitions.json\n" }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_search_service.name; stream_name = "build" }; s3_logs { status = "ENABLED"; location = "${aws_s3_bucket.infra["codebuild-cache"].id}/search-service/logs" } }
}
resource "aws_codebuild_project" "test_search_service" {
  name = "search-service-test"; description = "Tests for search-service"; build_timeout = 20
  service_role = aws_iam_role.codebuild_search_service.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"; image = "aws/codebuild/standard:7.0"; type = "LINUX_CONTAINER"; image_pull_credentials_type = "CODEBUILD"; privileged_mode = false
    environment_variable { name = "SERVICE_NAME"; value = "search-service" }
    environment_variable { name = "DB_CONNECTION"; value = "/search-service/database/connection"; type = "PARAMETER_STORE" }
  }
  source { type = "CODEPIPELINE"; buildspec = local.codebuild_test_buildspec }
  logs_config { cloudwatch_logs { group_name = aws_cloudwatch_log_group.codebuild_search_service.name; stream_name = "test" } }
}

resource "aws_codebuild_project" "security_scan" {
  name          = "security-scan"
  description   = "SAST and dependency scanning"
  build_timeout = 15
  service_role  = aws_iam_role.codebuild_api_gateway.arn

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

resource "aws_codepipeline" "api_gateway" {
  name     = "api-gateway-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/api-gateway"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_api_gateway.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_api_gateway.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "api-gateway"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of api-gateway" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "api-gateway"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
}

resource "aws_codepipeline" "user_service" {
  name     = "user-service-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/user-service"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_user_service.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_user_service.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "user-service"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of user-service" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "user-service"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
}

resource "aws_codepipeline" "order_service" {
  name     = "order-service-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/order-service"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_order_service.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_order_service.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "order-service"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of order-service" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "order-service"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
}

resource "aws_codepipeline" "payment_service" {
  name     = "payment-service-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/payment-service"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_payment_service.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_payment_service.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "payment-service"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of payment-service" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "payment-service"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
}

resource "aws_codepipeline" "inventory_service" {
  name     = "inventory-service-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/inventory-service"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_inventory_service.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_inventory_service.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "inventory-service"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of inventory-service" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "inventory-service"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
}

resource "aws_codepipeline" "notification_service" {
  name     = "notification-service-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/notification-service"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_notification_service.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_notification_service.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "notification-service"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of notification-service" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "notification-service"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
}

resource "aws_codepipeline" "catalog_service" {
  name     = "catalog-service-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/catalog-service"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_catalog_service.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_catalog_service.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "catalog-service"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of catalog-service" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "catalog-service"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
}

resource "aws_codepipeline" "search_service" {
  name     = "search-service-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store { location = aws_s3_bucket.infra["codepipeline-artifacts"].bucket; type = "S3"; encryption_key { id = aws_kms_key.s3.arn; type = "KMS" } }
  stage { name = "Source"; action { name = "Source"; category = "Source"; owner = "AWS"; provider = "CodeStarSourceConnection"; version = "1"; output_artifacts = ["source_output"]; configuration = { ConnectionArn = aws_codestarconnections_connection.github.arn; FullRepositoryId = "myorg/search-service"; BranchName = "main" } } }
  stage { name = "Test"; action { name = "UnitTest"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["test_output"]; configuration = { ProjectName = aws_codebuild_project.test_search_service.name } } }
  stage { name = "Build"; action { name = "BuildAndPush"; category = "Build"; owner = "AWS"; provider = "CodeBuild"; version = "1"; input_artifacts = ["source_output"]; output_artifacts = ["build_output"]; configuration = { ProjectName = aws_codebuild_project.build_search_service.name } } }
  stage { name = "DeployStaging"; action { name = "DeployToStaging"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["staging"].name; ServiceName = "search-service"; FileName = "imagedefinitions.json" } } }
  stage { name = "Approval"; action { name = "ManualApproval"; category = "Approval"; owner = "AWS"; provider = "Manual"; version = "1"; configuration = { NotificationArn = aws_sns_topic.main["deployment-events"].arn; CustomData = "Verify staging of search-service" } } }
  stage { name = "DeployProd"; action { name = "DeployToProduction"; category = "Deploy"; owner = "AWS"; provider = "ECS"; version = "1"; input_artifacts = ["build_output"]; configuration = { ClusterName = aws_ecs_cluster.main["prod"].name; ServiceName = "search-service"; FileName = "imagedefinitions.json"; DeploymentTimeout = "15" } } }
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
    service_name = "api-gateway"
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
