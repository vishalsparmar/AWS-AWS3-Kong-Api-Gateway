# terraform/control-plane.tf

terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "~> 0.3"
    }
  }
}

# Configure Konnect Provider
provider "konnect" {
  personal_access_token = "wewewe"
  server_url           = var.konnect_server_url
}

# Variables
variable "konnect_token" {
  description = "Konnect Personal Access Token"
  type        = string
  sensitive   = true
}

variable "konnect_server_url" {
  description = "Konnect server URL"
  type        = string
  default     = "https://eu.api.konghq.com"
}

variable "control_plane_name" {
  description = "Name of the control plane"
  type        = string
  default="VP_TEST"
}

variable "control_plane_description" {
  description = "Description of the control plane"
  type        = string
  default     = "Control plane created via Terraform"
}

variable "cluster_type" {
  description = "Type of cluster (CLUSTER_TYPE_HYBRID or CLUSTER_TYPE_K8S_INGRESS_CONTROLLER)"
  type        = string
  default     = "CLUSTER_TYPE_HYBRID"
}

variable "auth_type" {
  description = "Authentication type (pinned_client_certs or pki_client_certs)"
  type        = string
  default     = "pinned_client_certs"
}

# Create Control Plane
resource "konnect_gateway_control_plane" "main" {
  name         = var.control_plane_name
  description  = var.control_plane_description
  cluster_type = var.cluster_type
  auth_type    = var.auth_type

  # Optional: Add labels
  labels = {
    environment = "production"
    team        = "platform"
    managed_by  = "terraform"
  }
}


# Outputs - All the connection details you need
output "control_plane_id" {
  description = "Control Plane ID"
  value       = konnect_gateway_control_plane.main.id
}

output "control_plane_name" {
  description = "Control Plane Name"
  value       = konnect_gateway_control_plane.main.name
}





output "telemetry_endpoint" {
  description = "Telemetry endpoint for data plane metrics"
  value       = konnect_gateway_control_plane.main.config.telemetry_endpoint
}



# Additional useful outputs
output "control_plane_config" {
  description = "Complete control plane configuration"
  value = {
    id                        = konnect_gateway_control_plane.main.id
    name                      = konnect_gateway_control_plane.main.name
    control_plane_endpoint    = konnect_gateway_control_plane.main.config.control_plane_endpoint
    telemetry_endpoint        = konnect_gateway_control_plane.main.config.telemetry_endpoint
  }
}


provider "aws" {
  region = "us-east-1"
}

# Example: Storing a simple string parameter
resource "aws_ssm_parameter" "app_config" {
  name        = "/myapp/config/db_url" # hierarchical path is recommended
  description = "Database connection URL for myapp"
  type        = "String"               # String | StringList | SecureString
  value       = "postgres://user:pass@host:5432/mydb"
  overwrite   = true
  tier        = "Standard"             # Can be "Standard" or "Advanced"
  tags = {
    Environment = "dev"
    Application = "myapp"
  }
}

# Example: Storing a secure parameter (encrypted)
resource "aws_ssm_parameter" "app_secret" {
  name        = "/myapp/secret/api_key"
  description = "API Key for external service"
  type        = "SecureString" # Encrypted using AWS KMS
  value       = "super-secret-key"
  key_id      = "alias/aws/ssm" # Optionally, use a custom KMS key ARN
  overwrite   = true
}

