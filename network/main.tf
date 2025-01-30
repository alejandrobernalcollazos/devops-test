# Setup the networking
# Create VPC and subnets for the primary region
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = var.vpc_name
  cidr    = var.vpc_cidr
  azs     = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create a transit gateway for connecting VPCs
resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn = var.transit_gateway_amazon_side_asn
  description     = "Transit Gateway"
}

# Attach the VPCs to the transit gateways
resource "aws_ec2_transit_gateway_vpc_attachment" "transite_gateway_to_vpc_attachment" {
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
}

