resource "aws_vpc_peering_connection" "account_2" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = "vpc-0ea1858f8da3c0b3b"
  peer_owner_id = "722713121070"
  peer_region   = "ca-central-1"
  auto_accept   = false

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Side = "Requester"
  }
}

resource "aws_route" "account_2" {
  count                     = length(module.vpc.private_route_table_ids)
  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = "172.2.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.account_2.id
}
