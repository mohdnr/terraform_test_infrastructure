data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "elb" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name                  = var.vpc_name
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Internet Gateway:
# Allow VPC resources to communicate with the internet
#
resource "aws_internet_gateway" "elb" {
  vpc_id = aws_vpc.elb.id

  tags = {
    Name                  = var.vpc_name
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Subnets:
# 3 public and 3 private subnets
#
resource "aws_subnet" "elb_private" {
  count = 3

  vpc_id            = aws_vpc.elb.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name                  = "Private Subnet 0${count.index + 1}"
    (var.billing_tag_key) = var.billing_tag_value
    Access                = "private"
    Terraform             = true
  }
}

resource "aws_subnet" "elb_public" {
  count = 3

  vpc_id            = aws_vpc.elb.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + 3)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name                  = "Public Subnet 0${count.index + 1}"
    (var.billing_tag_key) = var.billing_tag_value
    Access                = "public"
    Terraform             = true
  }
}

data "aws_subnet_ids" "ecr_endpoint_available" {
  vpc_id = aws_vpc.elb.id
  filter {
    name   = "tag:Access"
    values = ["private"]
  }
  filter {
    name   = "availability-zone"
    values = ["ca-central-1a", "ca-central-1b"]
  }
  depends_on = [aws_subnet.elb_private]
}

data "aws_subnet_ids" "lambda_endpoint_available" {
  vpc_id = aws_vpc.elb.id
  filter {
    name   = "tag:Access"
    values = ["private"]
  }
  filter {
    name   = "availability-zone"
    values = ["ca-central-1a", "ca-central-1b"]
  }
  depends_on = [aws_subnet.elb_private]
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.elb.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_load_balancer" {
  name        = "elb-load-balancer"
  description = "Ingress - elb Load Balancer"
  vpc_id      = aws_vpc.elb.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# NAT Gateway
# Allows private resources to access the internet
#
resource "aws_nat_gateway" "elb" {
  count = 3

  allocation_id = aws_eip.elb_natgw.*.id[count.index]
  subnet_id     = aws_subnet.elb_public.*.id[count.index]

  tags = {
    Name                  = "${var.vpc_name} NAT GW"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }

  depends_on = [aws_internet_gateway.elb]
}

resource "aws_eip" "elb_natgw" {
  count = 3
  vpc   = true

  tags = {
    Name                  = "${var.vpc_name} NAT GW ${count.index}"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Routes
#
resource "aws_route_table" "elb_public_subnet" {
  vpc_id = aws_vpc.elb.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.elb.id
  }

  tags = {
    Name                  = "Public Subnet Route Table"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_route_table_association" "elb" {
  count = 3

  subnet_id      = aws_subnet.elb_public.*.id[count.index]
  route_table_id = aws_route_table.elb_public_subnet.id
}

resource "aws_route_table" "elb_private_subnet" {
  count = 3

  vpc_id = aws_vpc.elb.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.elb.*.id[count.index]
  }

  tags = {
    Name                  = "Private Subnet Route Table ${count.index}"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_route_table_association" "elb_private_route" {
  count = 3

  subnet_id      = aws_subnet.elb_private.*.id[count.index]
  route_table_id = aws_route_table.elb_private_subnet.*.id[count.index]
}

#
# Load balancer
#
resource "aws_lb" "elb_viewer" {
  name               = "elb-viewer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_load_balancer.id]
  subnets            = aws_subnet.elb_public.*.id

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = "cbs-satellite-${data.aws_caller_identity.current.account_id}"
    prefix  = "lb_logs"
    enabled = true
  }

  tags = {
    Name                  = "elb_viewer"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lb_target_group" "elb_viewer_1" {
  name                 = "elb-viewer"
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "instance"
  deregistration_delay = 30
  vpc_id               = aws_vpc.elb.id

  tags = {
    Name                  = "elb_viewer_1"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lb_target_group_attachment" "elb_viewer_1" {
  count            = 2
  target_group_arn = aws_lb_target_group.elb_viewer_1.arn
  target_id        = module.ec2_instances.id[count.index]
  port             = 8080
}



################
# EC2 instances
################
module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count = 2

  name                        = "my-app"
  ami                         = "ami-5ac17f3e"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_default_security_group.default.id]
  subnet_id                   = aws_subnet.elb_private[0].id
  associate_public_ip_address = true
}

resource "aws_lb" "elb-logging-test" {
  name               = "elb-logging-test"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_load_balancer.id]
  subnets            = aws_subnet.elb_public.*.id

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = {
    Name                  = "elb_viewer"
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
