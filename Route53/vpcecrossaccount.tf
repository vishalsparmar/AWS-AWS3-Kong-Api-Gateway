# backend.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket  = "your-terraform-state-bucket"
    key     = "vpc-endpoint-lookup/terraform.tfstate"
    region  = "us-west-2"
    profile = "main-account-profile"
    encrypt = true
  }
}

# providers.tf
provider "aws" {
  # Default provider for your main account
  profile = "main-account-profile"
  region  = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "vpc-endpoint-lookup"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "other_account"
  region = var.aws_region
  
  assume_role {
    role_arn     = "arn:aws:iam::${var.other_account_id}:role/${var.cross_account_role_name}"
    session_name = "terraform-vpc-endpoint-lookup"
    external_id  = var.external_id # Optional: if your role requires external ID
  }
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "vpc-endpoint-lookup"
      ManagedBy   = "terraform"
    }
  }
}

# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "other_account_id" {
  description = "Other AWS account ID where VPC endpoints exist"
  type        = string
  # Example: "123456789012"
}

variable "cross_account_role_name" {
  description = "Name of the cross-account role to assume"
  type        = string
  default     = "TerraformCrossAccountRole"
}

variable "external_id" {
  description = "External ID for cross-account role (optional)"
  type        = string
  default     = null
}

variable "target_vpc_id" {
  description = "VPC ID in other account to lookup endpoints for"
  type        = string
  # Example: "vpc-1234567890abcdef0"
}

variable "service_names" {
  description = "List of AWS service names to filter VPC endpoints"
  type        = list(string)
  default     = [
    "com.amazonaws.us-west-2.s3",
    "com.amazonaws.us-west-2.dynamodb",
    "com.amazonaws.us-west-2.ec2"
  ]
}

# main.tf - Data sources for VPC endpoint lookups
# Lookup all VPC endpoints in the target VPC
data "aws_vpc_endpoints" "other_account_all" {
  provider = aws.other_account
  
  filter {
    name   = "vpc-id"
    values = [var.target_vpc_id]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Lookup specific service endpoints
data "aws_vpc_endpoints" "other_account_s3" {
  provider = aws.other_account
  
  filter {
    name   = "vpc-id"
    values = [var.target_vpc_id]
  }
  
  filter {
    name   = "service-name"
    values = ["com.amazonaws.${var.aws_region}.s3"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Lookup VPC endpoint by specific ID (if you know it)
data "aws_vpc_endpoint" "specific_endpoint" {
  provider = aws.other_account
  
  # Uncomment and provide specific endpoint ID if needed
  # id = "vpce-1234567890abcdef0"
  
  # Or lookup by service name in specific VPC
  filter {
    name   = "vpc-id"
    values = [var.target_vpc_id]
  }
  
  filter {
    name   = "service-name"
    values = ["com.amazonaws.${var.aws_region}.dynamodb"]
  }
  
  count = length(data.aws_vpc_endpoints.other_account_all.ids) > 0 ? 1 : 0
}

# Get VPC details from other account
data "aws_vpc" "other_account_vpc" {
  provider = aws.other_account
  id       = var.target_vpc_id
}

# Example: Create security group in your main account that allows traffic to other account's VPC endpoints
resource "aws_security_group" "vpc_endpoint_access" {
  name_prefix = "vpc-endpoint-access-"
  description = "Allow access to VPC endpoints in other account"
  vpc_id      = data.aws_vpc.main_vpc.id
  
  # Allow HTTPS traffic to VPC endpoints
  dynamic "egress" {
    for_each = data.aws_vpc_endpoints.other_account_s3.ids
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.other_account_vpc.cidr_block]
      description = "HTTPS to S3 VPC endpoint in other account"
    }
  }
  
  # Allow HTTP traffic if needed
  dynamic "egress" {
    for_each = data.aws_vpc_endpoints.other_account_s3.ids
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.other_account_vpc.cidr_block]
      description = "HTTP to S3 VPC endpoint in other account"
    }
  }
  
  tags = {
    Name = "vpc-endpoint-access-${var.environment}"
  }
}

# Get your main VPC (assuming it exists)
data "aws_vpc" "main_vpc" {
  # You can filter by name, tags, or specify ID
  filter {
    name   = "tag:Name"
    values = ["main-vpc-${var.environment}"]
  }
}

# outputs.tf
output "other_account_vpc_endpoints" {
  description = "All VPC endpoints in other account"
  value = {
    ids           = data.aws_vpc_endpoints.other_account_all.ids
    service_names = data.aws_vpc_endpoints.other_account_all.service_names
  }
}

output "s3_vpc_endpoints" {
  description = "S3 VPC endpoints in other account"
  value = {
    ids    = data.aws_vpc_endpoints.other_account_s3.ids
    vpc_id = var.target_vpc_id
  }
}

output "other_account_vpc_info" {
  description = "VPC information from other account"
  value = {
    vpc_id     = data.aws_vpc.other_account_vpc.id
    cidr_block = data.aws_vpc.other_account_vpc.cidr_block
    state      = data.aws_vpc.other_account_vpc.state
  }
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account role being used"
  value       = "arn:aws:iam::${var.other_account_id}:role/${var.cross_account_role_name}"
}

# terraform.tfvars.example
# Copy this to terraform.tfvars and fill in your values
# aws_region = "us-west-2"
# environment = "dev"
# other_account_id = "123456789012"
# cross_account_role_name = "TerraformCrossAccountRole"
# target_vpc_id = "vpc-1234567890abcdef0"
# external_id = "your-external-id" # Optional
