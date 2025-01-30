output "vpc_private_route_table_id" {
  description = "The ID of the private route table"
  value       = module.vpc.private_route_table_ids[0]
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "transit_gateway_id" {
  description = "The ID of the transit gateway"
  value       = aws_ec2_transit_gateway.tgw.id
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group"
  value       = module.vpc.default_security_group_id
}