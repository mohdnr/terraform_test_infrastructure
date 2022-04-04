#
# Load balancer
#
resource "aws_lb" "cartography" {
  name               = "cartography"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cartography.id]
  subnets            = module.vpc.public_subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "ecs" {
  name                 = "ecs"
  port                 = 7474
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = module.vpc.vpc_id

  health_check {
    protocol            = "HTTP"
    path                = ""
    port                = "traffic-port"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10
    interval            = 15
    matcher             = "200-399"
  }

  tags = {
    billing_tag_key   = "CostCentre"
    billing_tag_value = var.billing_code
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.cartography.arn

  port            = 443
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.self_signed_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

resource "aws_lb_listener_certificate" "https_sni" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = aws_acm_certificate.self_signed_cert.arn
}
