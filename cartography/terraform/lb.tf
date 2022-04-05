#
# Load balancer
#
resource "aws_lb" "cartography" {
  name               = "cartography"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "ecs" {
  name                 = "ecs"
  port                 = 7474
  protocol             = "TCP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = module.vpc.vpc_id

  tags = {
    billing_tag_key   = "CostCentre"
    billing_tag_value = var.billing_code
  }
}

resource "aws_lb_target_group" "bolt" {
  name                 = "bolt"
  port                 = 7687
  protocol             = "TCP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = module.vpc.vpc_id

  tags = {
    billing_tag_key   = "CostCentre"
    billing_tag_value = var.billing_code
  }
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.cartography.arn

  port     = 7474
  protocol = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

resource "aws_lb_listener" "bolt" {
  load_balancer_arn = aws_lb.cartography.arn

  port     = 7687
  protocol = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bolt.arn
  }
}
