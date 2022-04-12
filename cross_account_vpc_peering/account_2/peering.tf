# resource "aws_vpc_peering_connection_accepter" "peer" {
#   vpc_peering_connection_id = "vpc-08c1c06a41b5102a8"
#   auto_accept               = true

#   tags = {
#     Side = "Accepter"
#   }
# }

# data "aws_route_tables" "account_1" {
#   vpc_id = module.vpc.vpc_id
# }

# resource "aws_route" "account_1" {
#   route_table_id            = data.aws_route_tables.account_1.id
#   destination_cidr_block    = aws_vpc_ipv4_cidr_block_association.account_1_cidr.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.account_1.id
# }
