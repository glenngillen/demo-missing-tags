output "vpc_ids" {
  value = { for k, v in aws_vpc.main : k => v.id }
}

output "alb_dns_names" {
  value = { for k, v in aws_lb.main : k => v.dns_name }
}

output "api_alb_dns_names" {
  value = { for k, v in aws_lb.api : k => v.dns_name }
}

output "rds_endpoints" {
  value     = { for k, v in aws_db_instance.main : k => v.address }
  sensitive = true
}

output "redis_endpoints" {
  value     = { for k, v in aws_elasticache_replication_group.main : k => v.primary_endpoint_address }
  sensitive = true
}

output "ecs_cluster_arns" {
  value = { for k, v in aws_ecs_cluster.main : k => v.arn }
}

output "ecr_repository_urls" {
  value = { for k, v in aws_ecr_repository.microservices : k => v.repository_url }
}

output "eks_cluster_endpoints" {
  value     = { for k, v in aws_eks_cluster.main : k => v.endpoint }
  sensitive = true
}

output "cloudfront_domain_names" {
  value = {
    main   = aws_cloudfront_distribution.main.domain_name
    static = aws_cloudfront_distribution.static.domain_name
    admin  = aws_cloudfront_distribution.admin.domain_name
  }
}

output "cognito_user_pool_ids" {
  value = { for k, v in aws_cognito_user_pool.main : k => v.id }
}

output "opensearch_endpoints" {
  value = { for k, v in aws_opensearch_domain.main : k => v.endpoint }
}

output "msk_bootstrap_brokers" {
  value     = { for k, v in aws_msk_cluster.main : k => v.bootstrap_brokers_tls }
  sensitive = true
}

output "redshift_endpoint" {
  value     = aws_redshift_cluster.main.endpoint
  sensitive = true
}

output "kinesis_stream_arns" {
  value = {
    events      = aws_kinesis_stream.events.arn
    clickstream = aws_kinesis_stream.clickstream.arn
    audit_log   = aws_kinesis_stream.audit_log.arn
    metrics     = aws_kinesis_stream.metrics.arn
  }
}

output "sqs_queue_urls" {
  value = { for k, v in aws_sqs_queue.main : k => v.id }
}

output "sns_topic_arns" {
  value = { for k, v in aws_sns_topic.main : k => v.arn }
}

output "kms_key_arns" {
  value = {
    rds         = aws_kms_key.rds.arn
    s3          = aws_kms_key.s3.arn
    ssm         = aws_kms_key.ssm.arn
    secrets     = aws_kms_key.secrets.arn
    cloudwatch  = aws_kms_key.cloudwatch.arn
    elasticache = aws_kms_key.elasticache.arn
    sqs         = aws_kms_key.sqs.arn
    sns         = aws_kms_key.sns.arn
    kinesis     = aws_kms_key.kinesis.arn
  }
}

output "step_function_arns" {
  value = {
    order_fulfillment = aws_sfn_state_machine.order_fulfillment.arn
    data_pipeline     = aws_sfn_state_machine.data_pipeline.arn
    user_onboarding   = aws_sfn_state_machine.user_onboarding.arn
  }
}

output "nat_gateway_ips" {
  value = { for k, v in aws_eip.nat : k => v.public_ip }
}

output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.main.arn
}

output "codepipeline_names" {
  value = { for k, v in aws_codepipeline.main : k => v.name }
}
