# Dev Environment Setup

## Overview

This Terraform configuration sets up a dev environment in AWS, including a VPC, subnets, Internet Gateway, security groups, RDS PostgreSQL instance, and EC2 instance.

## Prerequisites

*   Install [Terraform](https://www.terraform.io/) on your machine.
*   Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) on your machine.
*   Set up an AWS account with the necessary credentials (access key ID and secret access key).
*   Ensure that you have the `aws` provider version 4.16 or higher installed in your Terraform configuration.

### Disclaimer
This project assumes your account is elegible for the AWS free tier, if it's not, update the `instance_class` from `rds_instance` *AND* `instance_type` from `app_server` 

## How to Use

1.  Clone this repository or create a new directory and copy the contents of `main.tf` file.
2.  Install any required providers by running `terraform init`.
3.  Update the `main.tf` file with your desired environment variables (e.g., region, availability zones, etc.).
4.  Run `terraform apply` to provision the resources in your AWS account.

## Output Values

After successful deployment, you can access the following output values:

*   `rds_endpoint`: The endpoint for connecting to the RDS PostgreSQL instance.
*   `ec2_public_ip`: The public IP address of the EC2 instance.

Note: This is a basic example and might require modifications based on your specific requirements.

## Example Usage

```bash
# Initialize Terraform
terraform init

# Set up environment variables (optional)
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"

# Apply the configuration
terraform apply
```

Make sure to replace `your_access_key_id` and `your_secret_access_key` with your actual AWS credentials.

## Troubleshooting

If you encounter any issues during deployment, please refer to the Terraform documentation for troubleshooting guidance. Additionally, you can 
try running `terraform console` to interactively debug your configuration.
