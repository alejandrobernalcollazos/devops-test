variable "ami" {
    description = "The ID of the AMI to use for the instance"
    type        = string
    default     = "ami-093a4ad9a8cc370f4"
}

variable "instance_type" {
    description = "The type of instance to launch"
    type        = string
    default     = "t2.micro"
}

variable "name" {
    description = "The name of the EC2 instance"
    type        = string
    default     = "DevOpsTestInstance"
}

variable "mariadb_endpoint" {
    description = "The endpoint of the MariaDB instance"
    type        = string
}

variable "subnet_id" {
    description = "The ID of the subnet to launch the instance in"
    type        = string
}

variable "security_groups" {
    description = "A list of security group IDs to associate with the instance"
    type        = list(string)
    default     = []
}

variable "associate_public_ip_address" {
    description = "Associate a public IP address with the instance"
    type        = bool
    default     = true
}