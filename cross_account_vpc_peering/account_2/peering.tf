resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = local.peering_connection_id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_vpc_peering_connection_options" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id

  accepter {
    allow_remote_vpc_dns_resolution  = true
    allow_classic_link_to_remote_vpc = false
    allow_vpc_to_remote_classic_link = false
  }
}

resource "aws_route" "account_1" {
  count                     = length(module.vpc.private_route_table_ids)
  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = "172.2.0.0/16"
  vpc_peering_connection_id = local.peering_connection_id
}
