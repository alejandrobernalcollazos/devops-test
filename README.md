# Terraform Project

This repository contains Terraform configurations for managing infrastructure for a simple php application that uses a MariaDB

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.7.4 or later

## Getting Started

1. **Clone the repository:**
    ```sh
    git clone https://github.com/alejandrobernalcollazos/devops-test
    cd devops-test
    ```

2. **Initialize Terraform:**
    ```sh
    terraform init
    ```

3. **Review and apply the Terraform plan:**
    ```sh
    terraform plan
    terraform apply
    ```

## Architecture

### Multi Region Deployment

This is a multi region deployment in AWS in the following regions

- `us-west-2` - Oregon
- `us-east-1` - N. Virginia

### Networking

At the networking level we have a VPC in each one of the regions with 

- `1 public` - Subnet (used for the EC2 instance running the app will use)
- `1 private` - Subnet (used for the DB instance of MariaDB)

For each of the subnets we have a routing table that manage the connectivity. The public subnets contains routes to internet through an Internet gateway, while at the private routing tables we have connectivity among the private subnets between the 2 VPC (us-west-2 and us-east-1) through a transit gateway.

We need connectivity among the private subnets in order to allow the Master DB (us-west-2) and the Replica DB (us-east-1) to communicate among each other to perform the replication operation.

The connectivity among the private subnets is made through a transit gateway and configured in the routing tables of each private subnet.

### The application

Consist of a simple php page loaded in an apache server, that interacts with the database to retrieve or create records of name and lastname of people. 

Basically we have the php application configured in a 

- EC2 instance 

and there is also a 

- database in MariaDB 

managed through the RDS service in AWS.

In front of the EC2 instance we configure a 

- loadbalancer 

With its 

- listener and target group 

in order to use HTTPS with the domain alejandroaws.com to receive HTTPS calls and then use HTTP to connect to the EC2 instance in the backend.

As an strategy for Disaster Recovery in case we lost a particular Region, we deployed all the components of the application in both regions, so one region serves as a secondary infrastructure that will receive requests in case the primary region goes down. In order to accomplish this we setup 

- 2 DNS records (zealous.alejandroaws.com)

One for the primary and another for the secondary with a health check in the primary region, when such health check fails the primary DNS record will be disabled and then the request will be routed to the secondary DNS record. 


## Project Structure

- `application` - This folder contains the module to setup the application infrastructure the EC2 instance.
- `rds` - This folder contains the module to setup the MariaDB infrastructure.
- `main.tf` - Its the main file that uses the application and rds modules to setup the infrastructure as well as the networking.
- `providers.tf` - Provider configurations.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Authors

- Alejandro Bernal
