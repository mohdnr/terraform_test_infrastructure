resource "aws_vpc_peering_connection" "account_2" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = "vpc-0781af06668ae0acb"
  peer_owner_id = "722713121070"
  peer_region   = "ca-central-1"
  auto_accept   = false

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Side = "Requester"
  }
}

data "aws_route_tables" "account_2" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_route" "account_2" {
  route_table_id            = data.aws_route_tables.account_2.id
  destination_cidr_block    = "172.2.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.account_2.id
}
