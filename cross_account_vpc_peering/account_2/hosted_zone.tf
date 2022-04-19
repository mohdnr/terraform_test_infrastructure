resource "aws_route53_zone" "internal_domain" {
  name = "hosted.cdssandbox.xyz"

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = {
    CostCenter = var.billing_code
  }
}

resource "aws_route53_vpc_association_authorization" "account_1" {
  vpc_id  = local.peer_vpc_id
  zone_id = aws_route53_zone.internal_domain.id
}
