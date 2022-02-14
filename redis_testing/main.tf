resource "random_password" "redis_token" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "redis_token" {
  name  = "redis_token"
  type  = "String"
  value = random_password.redis_token.result
}

module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v1.0.5//vpc"
  name   = "${var.product_name}_vpc"

  high_availability = false
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = false

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_code
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${var.product_name}-demo"
  replication_group_description = "Redis cluster for caching storage (has automatic eviction)"
  engine                        = "redis"
  node_type                     = "cache.t2.micro"
  number_cache_clusters         = 1
  parameter_group_name          = "default.redis6.x"
  engine_version                = "6.x"
  transit_encryption_enabled    = true
  auth_token                    = random_password.redis_token.result
  port                          = 6379
  security_group_ids            = [aws_security_group.inbound_to_redis.id]
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
}

####

resource "aws_network_acl_rule" "https" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "https_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO REDIS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.product_name}-redis"
  subnet_ids = module.vpc.public_subnet_ids
}

resource "aws_security_group" "inbound_to_redis" {
  name        = "inbound_to_redis"
  description = "Allow inbound traffic to redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Access to redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Access to TLS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
