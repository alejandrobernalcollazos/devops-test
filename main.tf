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
  public_subnets  = ["10.0.103.0/24", "10.0.104.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
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

}

/* module "rds_secondary" {
  source = "./rds"

  providers = {
    aws = aws.secondary
  }

  region            = var.secondary_region
  db_instance_class = "db.t3.medium"
  ...
} */

module "ec2_instance" {
  source = "./application"

  providers = {
    aws = aws.primary
  }

  ami              = "ami-093a4ad9a8cc370f4"
  instance_type    = "t2.micro"
  name             = "DevOpsTestInstance"
  mariadb_endpoint = module.rds_primary.db_endpoint
}