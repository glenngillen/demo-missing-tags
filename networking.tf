# ============================================================
# VPCs
# ============================================================

resource "aws_vpc" "main" {
  for_each             = var.vpc_cidrs
  cidr_block           = each.value
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# ============================================================
# Internet Gateways
# ============================================================

resource "aws_internet_gateway" "main" {
  for_each = var.vpc_cidrs
  vpc_id   = aws_vpc.main[each.key].id
}

# ============================================================
# Elastic IPs for NAT Gateways (3 per env = 9 total)
# ============================================================

resource "aws_eip" "nat" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key = "${env}-${idx}"
          env = env
          az  = az
          idx = idx
        }
      ]
    ]) : pair.key => pair
  }

  domain = "vpc"
}

# ============================================================
# NAT Gateways (3 per env = 9 total)
# ============================================================

resource "aws_nat_gateway" "main" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key = "${env}-${idx}"
          env = env
          az  = az
          idx = idx
        }
      ]
    ]) : pair.key => pair
  }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public["${each.value.env}-${each.value.idx}"].id

  depends_on = [aws_internet_gateway.main]
}

# ============================================================
# Public Subnets (3 per env = 9 total)
# ============================================================

resource "aws_subnet" "public" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key  = "${env}-${idx}"
          env  = env
          az   = az
          idx  = idx
          cidr = cidrsubnet(var.vpc_cidrs[env], 4, idx)
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id                  = aws_vpc.main[each.value.env].id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
}

# ============================================================
# Private App Subnets (3 per env = 9 total)
# ============================================================

resource "aws_subnet" "private" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key  = "${env}-${idx}"
          env  = env
          az   = az
          idx  = idx
          cidr = cidrsubnet(var.vpc_cidrs[env], 4, idx + 3)
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id            = aws_vpc.main[each.value.env].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

# ============================================================
# Private Database Subnets (3 per env = 9 total)
# ============================================================

resource "aws_subnet" "database" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key  = "${env}-${idx}"
          env  = env
          az   = az
          idx  = idx
          cidr = cidrsubnet(var.vpc_cidrs[env], 4, idx + 6)
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id            = aws_vpc.main[each.value.env].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

# ============================================================
# Route Tables — Public (1 per env = 3 total)
# ============================================================

resource "aws_route_table" "public" {
  for_each = toset(var.environments)
  vpc_id   = aws_vpc.main[each.key].id
}

resource "aws_route" "public_internet" {
  for_each               = toset(var.environments)
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key = "${env}-${idx}"
          env = env
          idx = idx
        }
      ]
    ]) : pair.key => pair
  }

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.value.env].id
}

# ============================================================
# Route Tables — Private (1 per AZ per env = 9 total)
# ============================================================

resource "aws_route_table" "private" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key = "${env}-${idx}"
          env = env
          idx = idx
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id = aws_vpc.main[each.value.env].id
}

resource "aws_route" "private_nat" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key = "${env}-${idx}"
          env = env
          idx = idx
        }
      ]
    ]) : pair.key => pair
  }

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key = "${env}-${idx}"
          env = env
          idx = idx
        }
      ]
    ]) : pair.key => pair
  }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "database" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for idx, az in var.availability_zones : {
          key = "${env}-${idx}"
          env = env
          idx = idx
        }
      ]
    ]) : pair.key => pair
  }

  subnet_id      = aws_subnet.database[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# ============================================================
# VPC Peering
# ============================================================

resource "aws_vpc_peering_connection" "prod_staging" {
  vpc_id      = aws_vpc.main["prod"].id
  peer_vpc_id = aws_vpc.main["staging"].id
  auto_accept = true
}

resource "aws_vpc_peering_connection" "prod_dev" {
  vpc_id      = aws_vpc.main["prod"].id
  peer_vpc_id = aws_vpc.main["dev"].id
  auto_accept = true
}

resource "aws_vpc_peering_connection" "staging_dev" {
  vpc_id      = aws_vpc.main["staging"].id
  peer_vpc_id = aws_vpc.main["dev"].id
  auto_accept = true
}

resource "aws_route" "prod_to_staging" {
  route_table_id            = aws_route_table.private["prod-0"].id
  destination_cidr_block    = var.vpc_cidrs["staging"]
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_staging.id
}

resource "aws_route" "staging_to_prod" {
  route_table_id            = aws_route_table.private["staging-0"].id
  destination_cidr_block    = var.vpc_cidrs["prod"]
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_staging.id
}

# ============================================================
# Network ACLs
# ============================================================

resource "aws_network_acl" "public" {
  for_each = toset(var.environments)
  vpc_id   = aws_vpc.main[each.key].id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
}

resource "aws_network_acl" "private" {
  for_each = toset(var.environments)
  vpc_id   = aws_vpc.main[each.key].id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidrs[each.key]
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
}

resource "aws_network_acl" "database" {
  for_each = toset(var.environments)
  vpc_id   = aws_vpc.main[each.key].id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidrs[each.key]
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.vpc_cidrs[each.key]
    from_port  = 6379
    to_port    = 6379
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.vpc_cidrs[each.key]
    from_port  = 3306
    to_port    = 3306
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }
}

# ============================================================
# VPC Flow Logs
# ============================================================

resource "aws_flow_log" "main" {
  for_each        = toset(var.environments)
  vpc_id          = aws_vpc.main[each.key].id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[each.key].arn
}

# ============================================================
# DB Subnet Groups
# ============================================================

resource "aws_db_subnet_group" "main" {
  for_each = toset(var.environments)
  name     = "${each.key}-db-subnet-group"

  subnet_ids = [
    aws_subnet.database["${each.key}-0"].id,
    aws_subnet.database["${each.key}-1"].id,
    aws_subnet.database["${each.key}-2"].id,
  ]
}

resource "aws_elasticache_subnet_group" "main" {
  for_each = toset(var.environments)
  name     = "${each.key}-redis-subnet-group"

  subnet_ids = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]
}

# ============================================================
# Security Groups
# ============================================================

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

# ============================================================
# VPC Endpoints
# ============================================================

resource "aws_vpc_endpoint" "s3" {
  for_each     = toset(var.environments)
  vpc_id       = aws_vpc.main[each.key].id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = [
    aws_route_table.private["${each.key}-0"].id,
    aws_route_table.private["${each.key}-1"].id,
    aws_route_table.private["${each.key}-2"].id,
  ]
}

resource "aws_vpc_endpoint" "dynamodb" {
  for_each     = toset(var.environments)
  vpc_id       = aws_vpc.main[each.key].id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"

  route_table_ids = [
    aws_route_table.private["${each.key}-0"].id,
    aws_route_table.private["${each.key}-1"].id,
    aws_route_table.private["${each.key}-2"].id,
  ]
}

resource "aws_vpc_endpoint" "ssm" {
  for_each            = toset(var.environments)
  vpc_id              = aws_vpc.main[each.key].id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]
}

resource "aws_vpc_endpoint" "secrets_manager" {
  for_each            = toset(var.environments)
  vpc_id              = aws_vpc.main[each.key].id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]
}

resource "aws_vpc_endpoint" "ecr_api" {
  for_each            = toset(var.environments)
  vpc_id              = aws_vpc.main[each.key].id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  for_each            = toset(var.environments)
  vpc_id              = aws_vpc.main[each.key].id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoints[each.key].id]
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private["${each.key}-0"].id,
    aws_subnet.private["${each.key}-1"].id,
    aws_subnet.private["${each.key}-2"].id,
  ]
}
