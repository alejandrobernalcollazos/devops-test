# Terraform Project

This repository contains Terraform configurations for managing infrastructure for a simple php application that uses a MariaDB

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.0.0 or later

## Getting Started

1. **Clone the repository:**
    ```sh
    git clone https://github.com/yourusername/your-repo.git
    cd your-repo
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

## Project Structure

- `db.tf` - Define the data base infrastructure.
- `server.tf` - Define the server infrastructure.
- `user-data.sh` - Template used for the setup of the php application and the apache server.
- `providers.tf` - Provider configurations.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Authors

- Alejandro Bernal
