# Setup the networking
# Create VPC and subnets for the primary region
module "vpc_primary" {
  source  = "terraform-aws-modules/vpc/aws"
  providers = {
    aws = aws.primary
  }
  name    = "primary-vpc"
  cidr    = "10.0.0.0/16"
  azs     = ["${var.primary_region}a", "${var.primary_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create VPC and subnets for the secondary region
module "vpc_secondary" {
  source  = "terraform-aws-modules/vpc/aws"
  providers = {
    aws = aws.secondary
  }
  name    = "secondary-vpc"
  cidr    = "10.1.0.0/16"
  azs     = ["${var.secondary_region}a", "${var.secondary_region}b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.103.0/24", "10.1.104.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Setting up transit gateway connectivity between the primary and secondary regions
# Create the primary transit gateway
resource "aws_ec2_transit_gateway" "primary_tgw" {
  amazon_side_asn = 64512
  description     = "Primary Transit Gateway"
}

# Create the secondary transit gateway
resource "aws_ec2_transit_gateway" "secondary_tgw" {
  provider        = aws.secondary
  amazon_side_asn = 64513
  description     = "Secondary Transit Gateway"
}

# Attach the VPCs to the transit gateways
resource "aws_ec2_transit_gateway_vpc_attachment" "primary_attachment" {
  vpc_id             = module.vpc_primary.vpc_id
  subnet_ids         = module.vpc_primary.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.primary_tgw.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "secondary_attachment" {
  provider          = aws.secondary
  vpc_id            = module.vpc_secondary.vpc_id
  subnet_ids        = module.vpc_secondary.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.secondary_tgw.id
}

# Settup the route tables for the transit gateways
# Primary VPC Route
resource "aws_route" "primary_to_tgw" {
  route_table_id         = module.vpc_primary.private_route_table_ids[0]
  destination_cidr_block = module.vpc_secondary.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.primary_tgw.id
}

# Secondary VPC Route
resource "aws_route" "secondary_to_tgw" {
  provider               = aws.secondary
  route_table_id         = module.vpc_secondary.private_route_table_ids[0]
  destination_cidr_block = module.vpc_primary.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.secondary_tgw.id
}

# Allow MySQL traffic between the VPCs
resource "aws_security_group_rule" "allow_mysql_primary" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = module.vpc_primary.default_security_group_id
  cidr_blocks       = [module.vpc_secondary.vpc_cidr_block]
}

# Allow outbout traffic for the primary default security group to internet
resource "aws_security_group_rule" "allow_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = module.vpc_primary.default_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_mysql_secondary" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = module.vpc_secondary.default_security_group_id
  cidr_blocks       = [module.vpc_primary.vpc_cidr_block]
}

# Create subnet group for the primary db
resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "primary-db-subnet-group"
  subnet_ids = module.vpc_primary.private_subnets
}

# Create subnet group for the secondary db
resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "secondary-db-subnet-group"
  subnet_ids = module.vpc_secondary.private_subnets
}

# Create the primary database
module "rds_primary" {
  source = "./rds"

  providers = {
    aws = aws.primary
  }

  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mariadb"
  engine_version    = "11.4.4"
  instance_class    = "db.t3.micro"
  db_name           = "sample"
  username          = "tutorial_user"
  password          = "masterpassword"
  parameter_group_name = "default.mariadb11.4"
  vpc_security_group_ids = [module.vpc_primary.default_security_group_id]
  db_subnet_group_name  = aws_db_subnet_group.primary.name
  backup_retention_period = 7

}

module "rds_secondary" {
  source = "./rds"

  providers = {
    aws = aws.secondary
  }

  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mariadb"
  engine_version    = "11.4.4"
  instance_class    = "db.t3.micro"
  vpc_security_group_ids = [module.vpc_secondary.default_security_group_id]
  db_subnet_group_name  = aws_db_subnet_group.secondary.name
  replicate_source_db   = module.rds_primary.db_arn
  backup_retention_period = 7
}



## Primary EC2 instance

## Create a security group for the web server
resource "aws_security_group" "web_sg_primary" {
  name        = "web-sg-primary"
  description = "Security group to allow ingress on port 80 and outbound to the internet"
  vpc_id      = module.vpc_primary.vpc_id

  # Ingress rule: Allow HTTP (port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IPv4 address
    ipv6_cidr_blocks = ["::/0"] # Allow traffic from any IPv6 address (optional)
  }

  # Ingress rule: Allow SSH (port 22) from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IPv4 address
    ipv6_cidr_blocks = ["::/0"] # Allow traffic from any IPv6 address (optional)
  }

  # Egress rule: Allow all outbound traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 allows all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to any IPv4 address
    ipv6_cidr_blocks = ["::/0"] # Allow traffic to any IPv6 address (optional)
  }

  tags = {
    Name = "web-sg-primary"
  }
}

# Allow aws_security_group.web_sg to access the primary RDS instance
resource "aws_security_group_rule" "allow_web_sg_to_rds_primary" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = module.vpc_primary.default_security_group_id
  source_security_group_id = aws_security_group.web_sg_primary.id
}

module "ec2_instance_primary" {
  source = "./application"

  providers = {
    aws = aws.primary
  }

  ami              = "ami-093a4ad9a8cc370f4"
  instance_type    = "t2.micro"
  name             = "DevOpsTestInstance"
  mariadb_endpoint = module.rds_primary.db_endpoint
  subnet_id        = module.vpc_primary.public_subnets[0]
  security_groups  = [module.vpc_primary.default_security_group_id, aws_security_group.web_sg_primary.id]
  associate_public_ip_address = true
}



## Secondary EC2 instance

## Create a security group for the web server
resource "aws_security_group" "web_sg_secundary" {
  provider    = aws.secondary
  name        = "web-sg-secundary"
  description = "Security group to allow ingress on port 80 and outbound to the internet"
  vpc_id      = module.vpc_secondary.vpc_id

  # Ingress rule: Allow HTTP (port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IPv4 address
    ipv6_cidr_blocks = ["::/0"] # Allow traffic from any IPv6 address (optional)
  }

  # Ingress rule: Allow SSH (port 22) from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from any IPv4 address
    ipv6_cidr_blocks = ["::/0"] # Allow traffic from any IPv6 address (optional)
  }

  # Egress rule: Allow all outbound traffic to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 allows all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to any IPv4 address
    ipv6_cidr_blocks = ["::/0"] # Allow traffic to any IPv6 address (optional)
  }

  tags = {
    Name = "web-sg-secundary"
  }
}

# Allow aws_security_group.web_sg to access the primary RDS instance
resource "aws_security_group_rule" "allow_web_sg_to_rds_secundary" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = module.vpc_secondary.default_security_group_id
  source_security_group_id = aws_security_group.web_sg_secundary.id
}

module "ec2_instance_secondary" {
  source = "./application"

  providers = {
    aws = aws.secondary
  }

  ami              = "ami-0ac4dfaf1c5c0cce9"
  instance_type    = "t2.micro"
  name             = "DevOpsTestInstanceSecondary"
  mariadb_endpoint = module.rds_secondary.db_endpoint
  subnet_id        = module.vpc_secondary.public_subnets[0]
  security_groups  = [module.vpc_secondary.default_security_group_id, aws_security_group.web_sg_secundary.id]
  associate_public_ip_address = true
}