# ============================================================
# Lambda Functions — Explicit definitions
# ============================================================

resource "aws_lambda_function" "process_order" {
  function_name = "process-order"
  role          = aws_iam_role.lambda_process_order.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "process-order" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "send_email" {
  function_name = "send-email"
  role          = aws_iam_role.lambda_send_email.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "send-email" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "resize_image" {
  function_name = "resize-image"
  role          = aws_iam_role.lambda_resize_image.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "resize-image" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "validate_payment" {
  function_name = "validate-payment"
  role          = aws_iam_role.lambda_validate_payment.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "validate-payment" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "sync_inventory" {
  function_name = "sync-inventory"
  role          = aws_iam_role.lambda_sync_inventory.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "sync-inventory" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "generate_report" {
  function_name = "generate-report"
  role          = aws_iam_role.lambda_generate_report.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "generate-report" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "cleanup_sessions" {
  function_name = "cleanup-sessions"
  role          = aws_iam_role.lambda_cleanup_sessions.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "cleanup-sessions" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "data_transformer" {
  function_name = "data-transformer"
  role          = aws_iam_role.lambda_data_transformer.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "data-transformer" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "notification_sender" {
  function_name = "notification-sender"
  role          = aws_iam_role.lambda_notification_sender.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "notification-sender" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_notifications.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "cache_warmer" {
  function_name = "cache-warmer"
  role          = aws_iam_role.lambda_cache_warmer.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "cache-warmer" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "batch_processor" {
  function_name = "batch-processor"
  role          = aws_iam_role.lambda_batch_processor.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "batch-processor" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "stream_consumer" {
  function_name = "stream-consumer"
  role          = aws_iam_role.lambda_stream_consumer.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "stream-consumer" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "api_authorizer" {
  function_name = "api-authorizer"
  role          = aws_iam_role.lambda_api_authorizer.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "api-authorizer" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "migrate_data" {
  function_name = "migrate-data"
  role          = aws_iam_role.lambda_migrate_data.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "migrate-data" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

resource "aws_lambda_function" "archive_records" {
  function_name = "archive-records"
  role          = aws_iam_role.lambda_archive_records.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = { ENVIRONMENT = "prod", LOG_LEVEL = "info", SERVICE_NAME = "archive-records" }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private["prod-0"].id, aws_subnet.private["prod-1"].id]
    security_group_ids = [aws_security_group.ecs_tasks["prod"].id]
  }

  tracing_config { mode = "Active" }
  dead_letter_config { target_arn = aws_sqs_queue.dead_letter_orders.arn }
  reserved_concurrent_executions = -1
  layers = [aws_lambda_layer_version.shared_utils.arn]

  
}

# ============================================================
# Lambda Event Invoke Configs
# ============================================================

resource "aws_lambda_function_event_invoke_config" "process_order" {
  function_name          = aws_lambda_function.process_order.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "send_email" {
  function_name          = aws_lambda_function.send_email.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "resize_image" {
  function_name          = aws_lambda_function.resize_image.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "validate_payment" {
  function_name          = aws_lambda_function.validate_payment.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "sync_inventory" {
  function_name          = aws_lambda_function.sync_inventory.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "generate_report" {
  function_name          = aws_lambda_function.generate_report.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "cleanup_sessions" {
  function_name          = aws_lambda_function.cleanup_sessions.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "data_transformer" {
  function_name          = aws_lambda_function.data_transformer.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "notification_sender" {
  function_name          = aws_lambda_function.notification_sender.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "cache_warmer" {
  function_name          = aws_lambda_function.cache_warmer.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "batch_processor" {
  function_name          = aws_lambda_function.batch_processor.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "stream_consumer" {
  function_name          = aws_lambda_function.stream_consumer.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "api_authorizer" {
  function_name          = aws_lambda_function.api_authorizer.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "migrate_data" {
  function_name          = aws_lambda_function.migrate_data.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

resource "aws_lambda_function_event_invoke_config" "archive_records" {
  function_name          = aws_lambda_function.archive_records.function_name
  maximum_retry_attempts = 2
  destination_config {
    on_failure { destination = aws_sqs_queue.dead_letter_notifications.arn }
  }
}

# ============================================================
# Lambda Aliases
# ============================================================

resource "aws_lambda_alias" "process_order_live" {
  name             = "live"
  function_name    = aws_lambda_function.process_order.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "send_email_live" {
  name             = "live"
  function_name    = aws_lambda_function.send_email.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "resize_image_live" {
  name             = "live"
  function_name    = aws_lambda_function.resize_image.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "validate_payment_live" {
  name             = "live"
  function_name    = aws_lambda_function.validate_payment.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "sync_inventory_live" {
  name             = "live"
  function_name    = aws_lambda_function.sync_inventory.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "generate_report_live" {
  name             = "live"
  function_name    = aws_lambda_function.generate_report.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "cleanup_sessions_live" {
  name             = "live"
  function_name    = aws_lambda_function.cleanup_sessions.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "data_transformer_live" {
  name             = "live"
  function_name    = aws_lambda_function.data_transformer.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "notification_sender_live" {
  name             = "live"
  function_name    = aws_lambda_function.notification_sender.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "cache_warmer_live" {
  name             = "live"
  function_name    = aws_lambda_function.cache_warmer.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "batch_processor_live" {
  name             = "live"
  function_name    = aws_lambda_function.batch_processor.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "stream_consumer_live" {
  name             = "live"
  function_name    = aws_lambda_function.stream_consumer.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "api_authorizer_live" {
  name             = "live"
  function_name    = aws_lambda_function.api_authorizer.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "migrate_data_live" {
  name             = "live"
  function_name    = aws_lambda_function.migrate_data.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "archive_records_live" {
  name             = "live"
  function_name    = aws_lambda_function.archive_records.function_name
  function_version = "$LATEST"
}

# ============================================================
# Lambda Permissions
# ============================================================

resource "aws_lambda_permission" "sqs_process_order" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_order.function_name
  principal     = "sqs.amazonaws.com"
}

resource "aws_lambda_permission" "sqs_send_email" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_email.function_name
  principal     = "sqs.amazonaws.com"
}

resource "aws_lambda_permission" "sqs_sync_inventory" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sync_inventory.function_name
  principal     = "sqs.amazonaws.com"
}

resource "aws_lambda_permission" "sqs_notification_sender" {
  statement_id  = "AllowSQSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_sender.function_name
  principal     = "sqs.amazonaws.com"
}

resource "aws_lambda_permission" "apigateway_api_authorizer" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "s3_resize_image" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize_image.function_name
  principal     = "s3.amazonaws.com"
}

resource "aws_lambda_permission" "eventbridge_cleanup_sessions" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup_sessions.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_lambda_permission" "eventbridge_cache_warmer" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cache_warmer.function_name
  principal     = "events.amazonaws.com"
}

resource "aws_lambda_permission" "eventbridge_generate_report" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_report.function_name
  principal     = "events.amazonaws.com"
}

# SQS event source mappings
resource "aws_lambda_event_source_mapping" "sqs_orders" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.process_order.arn
  batch_size       = 10

  scaling_config {
    maximum_concurrency = 100
  }
}

resource "aws_lambda_event_source_mapping" "sqs_notifications" {
  event_source_arn = aws_sqs_queue.notifications.arn
  function_name    = aws_lambda_function.notification_sender.arn
  batch_size       = 100

  scaling_config {
    maximum_concurrency = 50
  }
}

resource "aws_lambda_event_source_mapping" "sqs_emails" {
  event_source_arn = aws_sqs_queue.emails.arn
  function_name    = aws_lambda_function.send_email.arn
  batch_size       = 50
}

resource "aws_lambda_event_source_mapping" "sqs_image_processing" {
  event_source_arn = aws_sqs_queue.image_processing.arn
  function_name    = aws_lambda_function.resize_image.arn
  batch_size       = 5
}

resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn  = aws_kinesis_stream.events.arn
  function_name     = aws_lambda_function.stream_consumer.arn
  starting_position = "LATEST"
  batch_size        = 100

  bisect_batch_on_function_error = true

  destination_config {
    on_failure {
      destination_arn = aws_sqs_queue.dead_letter_notifications.arn
    }
  }
}

# Lambda Layer
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "/tmp/lambda_placeholder.zip"

  source {
    content  = "exports.handler = async (event) => ({ statusCode: 200, body: 'OK' });"
    filename  = "index.js"
  }
}

resource "aws_lambda_layer_version" "shared_utils" {
  layer_name          = "shared-utils"
  filename            = data.archive_file.lambda_placeholder.output_path
  compatible_runtimes = ["nodejs20.x", "nodejs18.x"]
}

resource "aws_lambda_layer_version" "aws_sdk" {
  layer_name          = "aws-sdk-v3"
  filename            = data.archive_file.lambda_placeholder.output_path
  compatible_runtimes = ["nodejs20.x"]
}

# Lambda Provisioned Concurrency (critical functions)
resource "aws_lambda_provisioned_concurrency_config" "api_authorizer" {
  function_name                     = aws_lambda_function.api_authorizer.function_name
  provisioned_concurrent_executions = 10
  qualifier                         = aws_lambda_alias.api_authorizer_live.name
}

resource "aws_lambda_provisioned_concurrency_config" "validate_payment" {
  function_name                     = aws_lambda_function.validate_payment.function_name
  provisioned_concurrent_executions = 10
  qualifier                         = aws_lambda_alias.validate_payment_live.name
}

# ============================================================
# API Gateway (REST)
# ============================================================

resource "aws_api_gateway_rest_api" "main" {
  name        = "main-api"
  description = "Main REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  
}

resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "orders"
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "products"
}

resource "aws_api_gateway_method" "get_users" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "post_users" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_orders" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "post_orders" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.main["prod"].arn]
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  depends_on = [
    aws_api_gateway_method.get_users,
    aws_api_gateway_method.post_users,
    aws_api_gateway_method.get_orders,
    aws_api_gateway_method.post_orders,
    aws_api_gateway_method.get_products,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
  }

  default_route_settings {}

  
}

resource "aws_api_gateway_stage" "staging" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "staging"

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
  }

  default_route_settings {}

  
}

resource "aws_api_gateway_usage_plan" "main" {
  name = "main-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  quota_settings {
    limit  = 1000000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 5000
    rate_limit  = 1000
  }
}

resource "aws_api_gateway_method_settings" "prod" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = false
    throttling_burst_limit = 5000
    throttling_rate_limit  = 1000
  }
}

# ============================================================
# API Gateway (HTTP v2)
# ============================================================

resource "aws_apigatewayv2_api" "websocket" {
  name                       = "websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"

  
}

resource "aws_apigatewayv2_api" "internal" {
  name          = "internal-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type", "x-amz-date", "authorization"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_origins = ["https://example.com", "https://staging.example.com"]
    max_age       = 300
  }

  
}

resource "aws_apigatewayv2_stage" "websocket_prod" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "prod"
  auto_deploy = false

  default_route_settings {
    logging_level            = "INFO"
    data_trace_enabled       = false
    detailed_metrics_enabled = true
    throttling_burst_limit   = 5000
    throttling_rate_limit    = 1000
  }
}

resource "aws_apigatewayv2_stage" "internal_prod" {
  api_id      = aws_apigatewayv2_api.internal.id
  name        = "prod"
  auto_deploy = true
}

# ============================================================
# Step Functions
# ============================================================

resource "aws_sfn_state_machine" "order_fulfillment" {
  name     = "order-fulfillment"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "Order fulfillment workflow"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type     = "Task"
        Resource = aws_lambda_function.validate_payment.arn
        Next     = "ProcessPayment"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2.0
        }]
      }
      ProcessPayment = {
        Type     = "Task"
        Resource = aws_lambda_function.validate_payment.arn
        Next     = "UpdateInventory"
      }
      UpdateInventory = {
        Type     = "Task"
        Resource = aws_lambda_function.sync_inventory.arn
        Next     = "SendConfirmation"
      }
      SendConfirmation = {
        Type     = "Task"
        Resource = aws_lambda_function.send_email.arn
        End      = true
      }
    }
  })

  
}

resource "aws_sfn_state_machine" "data_pipeline" {
  name     = "data-pipeline"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "Data processing pipeline"
    StartAt = "ExtractData"
    States = {
      ExtractData = {
        Type     = "Task"
        Resource = aws_lambda_function.data_transformer.arn
        Next     = "TransformData"
      }
      TransformData = {
        Type  = "Parallel"
        Next  = "LoadData"
        Branches = [
          {
            StartAt = "TransformUsers"
            States = {
              TransformUsers = {
                Type     = "Task"
                Resource = aws_lambda_function.data_transformer.arn
                End      = true
              }
            }
          },
          {
            StartAt = "TransformOrders"
            States = {
              TransformOrders = {
                Type     = "Task"
                Resource = aws_lambda_function.batch_processor.arn
                End      = true
              }
            }
          }
        ]
      }
      LoadData = {
        Type     = "Task"
        Resource = aws_lambda_function.migrate_data.arn
        End      = true
      }
    }
  })

  
}

resource "aws_sfn_state_machine" "user_onboarding" {
  name     = "user-onboarding"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "User onboarding workflow"
    StartAt = "SendWelcomeEmail"
    States = {
      SendWelcomeEmail = {
        Type     = "Task"
        Resource = aws_lambda_function.send_email.arn
        Next     = "WaitForVerification"
      }
      WaitForVerification = {
        Type    = "Wait"
        Seconds = 86400
        Next    = "CheckVerification"
      }
      CheckVerification = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.verified"
            BooleanEquals = true
            Next         = "ActivateAccount"
          }
        ]
        Default = "SendReminderEmail"
      }
      SendReminderEmail = {
        Type     = "Task"
        Resource = aws_lambda_function.send_email.arn
        End      = true
      }
      ActivateAccount = {
        Type     = "Task"
        Resource = aws_lambda_function.notification_sender.arn
        End      = true
      }
    }
  })

  
}
