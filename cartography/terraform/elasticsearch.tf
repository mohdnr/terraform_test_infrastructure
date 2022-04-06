resource "aws_elasticsearch_domain" "cartography" {
  domain_name           = "cartography"
  elasticsearch_version = "7.10"

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = aws_ssm_parameter.elasticsearch_user.value
      master_user_password = aws_ssm_parameter.elasticsearch_password.value
    }
  }

  cluster_config {
    instance_type = "t3.small.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 25
  }

  vpc_options {
    security_group_ids = [aws_security_group.cartography.id]
    subnet_ids         = [module.vpc.public_subnet_ids[0]]
  }
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name     = aws_elasticsearch_domain.cartography.domain_name
  access_policies = <<POLICIES
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "es:*",
              "Principal": "*",
              "Effect": "Allow",
              "Resource": "${aws_elasticsearch_domain.cartography.arn}/*"
          }
      ]
  }
  POLICIES
}
