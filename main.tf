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

# Create the primary EC2 instance
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

# Create a security group for the web_lb_primary load balancer
resource "aws_security_group" "alb_sg_primary" {
  name        = "alb-sg-primary"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = module.vpc_primary.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a loadbalancer to listen for 443 calls and forward them to the primary EC2 instance
resource "aws_lb" "web_lb_primary" {
  name               = "web-lb-primary"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg_primary.id]
  subnets            = module.vpc_primary.public_subnets
}

# Create a listener for the primary load balancer
resource "aws_lb_listener" "web_lb_listener_primary" {
  load_balancer_arn = aws_lb.web_lb_primary.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn_primary
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_lb_target_group_primary.arn
  }
}

# Create a target group for the primary load balancer
resource "aws_lb_target_group" "web_lb_target_group_primary" {
  name     = "web-lb-target-group-primary"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc_primary.vpc_id
}

# Attach the primary EC2 instance to the primary target group
resource "aws_lb_target_group_attachment" "web_lb_target_group_attachment_primary" {
  target_group_arn = aws_lb_target_group.web_lb_target_group_primary.arn
  target_id        = module.ec2_instance_primary.instance_id
  port             = 80
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

# Create the secondary EC2 instance
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

# Create a security group for the web_lb_secondary load balancer
resource "aws_security_group" "alb_sg_secondary" {
  provider    = aws.secondary
  name        = "alb-sg-secondary"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = module.vpc_secondary.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a loadbalancer to listen for 443 calls and forward them to the secondary EC2 instance
resource "aws_lb" "web_lb_secondary" {
  provider           = aws.secondary
  name               = "web-lb-secondary"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg_secondary.id]
  subnets            = module.vpc_secondary.public_subnets
}

# Create a listener for the secondary load balancer
resource "aws_lb_listener" "web_lb_listener_secondary" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.web_lb_secondary.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn_secondary
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_lb_target_group_secondary.arn
  }
}

# Create a target group for the secondary load balancer
resource "aws_lb_target_group" "web_lb_target_group_secondary" {
  provider = aws.secondary
  name     = "web-lb-target-group-secondary"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc_secondary.vpc_id
}

# Attach the primary EC2 instance to the secondary target group
resource "aws_lb_target_group_attachment" "web_lb_target_group_attachment_secondary" {
  provider         = aws.secondary
  target_group_arn = aws_lb_target_group.web_lb_target_group_secondary.arn
  target_id        = module.ec2_instance_secondary.instance_id
  port             = 80
}

# Create a route53 record for the primary load balancer zealous.alejandroaws.com

# data fetch the existing hosted zone
data "aws_route53_zone" "primary" {
  name = "alejandroaws.com"
}

# health check for alejandroaws.com
resource "aws_route53_health_check" "app_fqdn" {
  fqdn = "zealous.alejandroaws.com"
  port = 443
  type = "HTTPS"
  
  resource_path     = "/zealous.php"
  request_interval  = 30
  failure_threshold = 3
}

# Create a route53 record for the application pointing to the primary load balancer 
resource "aws_route53_record" "app_record_primary" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "zealous"
  type    = "A"
  alias {
    name                   = aws_lb.web_lb_primary.dns_name
    zone_id                = aws_lb.web_lb_primary.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.app_fqdn.id

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary-record" # Unique name for the record
}

# Create a route53 record for the application pointing to the secondary load balancer 
resource "aws_route53_record" "app_record_secondary" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "zealous"
  type    = "A"
  alias {
    name                   = aws_lb.web_lb_secondary.dns_name
    zone_id                = aws_lb.web_lb_secondary.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary-record" # Unique name for the record
}