# Create a security group for the Apache server
resource "aws_security_group" "apache_sg" {
  name_prefix = "apache-sg-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Update for stricter access control
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Create an SSH key pair resource
resource "aws_key_pair" "my_key" {
  key_name   = "my-ec2-key"
  public_key = file("./ssh-key/my-ec2-key.pub") # Path to your public key
}

# Read the user data template file
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh") # Path to your template file

  vars = {
    db_instance_endpoint = aws_db_instance.mariadb.endpoint
  }
}

# Create an EC2 instance
resource "aws_instance" "app_server" {
  ami             = "ami-093a4ad9a8cc370f4"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.apache_sg.name]
  key_name        = aws_key_pair.my_key.key_name

  tags = {
    Name = "ExampleAppServerInstance"
  }

  user_data = data.template_file.user_data.rendered
}