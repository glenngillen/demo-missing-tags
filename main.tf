terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "db_master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

# ------------------------------------------------------------
# ACM Certificates
# ------------------------------------------------------------

resource "aws_acm_certificate" "main" {
  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com", "api.example.com", "admin.example.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Service     = "web"
    Owner       = "platform"
    Environment = "Prod"
  }
}

resource "aws_acm_certificate" "cdn" {
  provider          = aws.secondary
  domain_name       = "static.example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Service     = "web"
    Owner       = "platform"
    Environment = "Prod"
  }
}

resource "aws_acm_certificate" "staging" {
  domain_name               = "staging.example.com"
  subject_alternative_names = ["*.staging.example.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Service     = "web"
    Owner       = "platform"
    Environment = "Prod"
  }
}

# ------------------------------------------------------------
# Route53
# ------------------------------------------------------------

resource "aws_route53_zone" "main" {
  name = "example.com"
  tags = {
    Service     = "networking"
    Owner       = "networkops"
    Environment = "Prod"
  }
}

resource "aws_route53_zone" "internal" {
  name = "internal.example.com"

  vpc {
    vpc_id = aws_vpc.main["prod"].id
  }
  tags = {
    Service     = "networking"
    Owner       = "networkops"
    Environment = "Prod"
  }
}

resource "aws_route53_record" "main_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main["prod"].dns_name
    zone_id                = aws_lb.main["prod"].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.api["prod"].dns_name
    zone_id                = aws_lb.api["prod"].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "staging" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "staging.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main["staging"].dns_name
    zone_id                = aws_lb.main["staging"].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dev" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "dev.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.main["dev"].dns_name
    zone_id                = aws_lb.main["dev"].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "MX"
  ttl     = 300

  records = [
    "10 mail1.example.com",
    "20 mail2.example.com",
  ]
}

resource "aws_route53_record" "txt_spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "TXT"
  ttl     = 300

  records = ["v=spf1 include:_spf.google.com ~all"]
}

resource "aws_route53_health_check" "main" {
  fqdn              = "example.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  tags = {
    Service     = "networking"
    Owner       = "networkops"
    Environment = "Prod"
  }
}

resource "aws_route53_health_check" "api" {
  fqdn              = "api.example.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  tags = {
    Service     = "networking"
    Owner       = "networkops"
    Environment = "Prod"
  }
}

# ------------------------------------------------------------
# SSM Parameters
# ------------------------------------------------------------

resource "aws_ssm_parameter" "db_host" {
  for_each = toset(var.environments)
  name     = "/${each.key}/database/host"
  type     = "String"
  value    = aws_db_instance.main[each.key].address
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_ssm_parameter" "db_password" {
  for_each = toset(var.environments)
  name     = "/${each.key}/database/password"
  type     = "SecureString"
  value    = random_password.db_master.result
  key_id   = aws_kms_key.ssm.id
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_ssm_parameter" "redis_host" {
  for_each = toset(var.environments)
  name     = "/${each.key}/redis/host"
  type     = "String"
  value    = aws_elasticache_replication_group.main[each.key].primary_endpoint_address
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_ssm_parameter" "app_secret" {
  for_each = toset(var.environments)
  name     = "/${each.key}/app/secret_key"
  type     = "SecureString"
  value    = random_password.db_master.result
  key_id   = aws_kms_key.ssm.id
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_ssm_parameter" "jwt_secret" {
  for_each = toset(var.environments)
  name     = "/${each.key}/app/jwt_secret"
  type     = "SecureString"
  value    = random_password.redis_auth.result
  key_id   = aws_kms_key.ssm.id
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_ssm_parameter" "stripe_key" {
  for_each = toset(var.environments)
  name     = "/${each.key}/integrations/stripe_key"
  type     = "SecureString"
  value    = "sk_test_placeholder_${each.key}"
  key_id   = aws_kms_key.ssm.id
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_ssm_parameter" "sendgrid_key" {
  for_each = toset(var.environments)
  name     = "/${each.key}/integrations/sendgrid_key"
  type     = "SecureString"
  value    = "SG.placeholder_${each.key}"
  key_id   = aws_kms_key.ssm.id
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_ssm_parameter" "twilio_sid" {
  for_each = toset(var.environments)
  name     = "/${each.key}/integrations/twilio_sid"
  type     = "SecureString"
  value    = "AC_placeholder_${each.key}"
  key_id   = aws_kms_key.ssm.id
  tags = {
    Service     = "platform"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

# ------------------------------------------------------------
# Secrets Manager
# ------------------------------------------------------------

resource "aws_secretsmanager_secret" "db_credentials" {
  for_each = toset(var.environments)
  name     = "${each.key}/database/credentials"
  kms_key_id = aws_kms_key.secrets.id
  tags = {
    Service     = "security"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  for_each  = toset(var.environments)
  secret_id = aws_secretsmanager_secret.db_credentials[each.key].id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_master.result
    host     = aws_db_instance.main[each.key].address
    port     = 5432
    dbname   = "appdb"
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  for_each = toset(var.environments)
  name     = "${each.key}/app/api_keys"
  kms_key_id = aws_kms_key.secrets.id
  tags = {
    Service     = "security"
    Owner       = "platform"
    Environment = each.key == "prod" ? "Prod" : each.key == "staging" ? "Stage" : "Dev"
  }
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  for_each  = toset(var.environments)
  secret_id = aws_secretsmanager_secret.api_keys[each.key].id
  secret_string = jsonencode({
    stripe  = "sk_test_placeholder"
    twilio  = "AC_placeholder"
    sendgrid = "SG_placeholder"
  })
}

resource "aws_secretsmanager_secret" "third_party_creds" {
  for_each = toset(["salesforce", "hubspot", "datadog", "pagerduty", "slack"])
  name     = "integrations/${each.key}/credentials"
  kms_key_id = aws_kms_key.secrets.id
  tags = {
    Service     = "security"
    Owner       = "platform"
    Environment = "Prod"
  }
}

resource "aws_secretsmanager_secret_version" "third_party_creds" {
  for_each  = toset(["salesforce", "hubspot", "datadog", "pagerduty", "slack"])
  secret_id = aws_secretsmanager_secret.third_party_creds[each.key].id
  secret_string = jsonencode({
    api_key = "placeholder_${each.key}"
    secret  = "secret_${each.key}"
  })
}

# ------------------------------------------------------------
# WAF
# ------------------------------------------------------------

resource "aws_wafv2_web_acl" "main" {
  name  = "main-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MainWAFMetric"
    sampled_requests_enabled   = true
  }
  tags = {
    Service     = "security"
    Owner       = "secops"
    Environment = "Prod"
  }
}

resource "aws_wafv2_web_acl" "cdn" {
  name  = "cdn-waf"
  scope = "CLOUDFRONT"
  provider = aws.secondary

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CDNCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CDNWAFMetric"
    sampled_requests_enabled   = true
  }
  tags = {
    Service     = "security"
    Owner       = "secops"
    Environment = "Prod"
  }
}

resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "blocked-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = []
  tags = {
    Service     = "security"
    Owner       = "secops"
    Environment = "Prod"
  }
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main["prod"].arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

resource "aws_wafv2_web_acl_association" "api" {
  resource_arn = aws_lb.api["prod"].arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
