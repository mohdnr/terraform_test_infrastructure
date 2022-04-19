resource "aws_route53_zone" "internal_domain" {
  name = "internal.cdssandbox.xyz"

  tags = {
    CostCenter = var.billing_code
  }
}

resource "aws_route53_zone_association" "account_1" {
  vpc_id  = module.vpc.vpc_id
  zone_id = local.peer_route53_zone_id
}
