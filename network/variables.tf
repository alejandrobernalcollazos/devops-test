variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_azs" {
  description = "The availability zones for the VPC"
  type        = list(string)
}

variable "vpc_private_subnets" {
  description = "The private subnets for the VPC"
  type        = list(string)
}

variable "vpc_public_subnets" {
  description = "The public subnets for the VPC"
  type        = list(string)
}

variable "transit_gateway_amazon_side_asn" {
  description = "The Amazon side ASN for the transit gateway"
  type        = number
}

variable "db_subnet_group_name" {
  description = "The name of the db subnet group"
  type        = string
}

