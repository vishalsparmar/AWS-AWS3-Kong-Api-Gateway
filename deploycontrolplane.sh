#!/bin/bash
# deploy-control-plane.sh

#set -e

echo "🚀 Creating Kong Control Plane in Konnect"

# Check if required tools are installed
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed. Aborting." >&2; ; }

# Configuration
TERRAFORM_DIR=${TERRAFORM_DIR:-"."}

echo "📋 Configuration:"
echo "  Terraform Directory: $TERRAFORM_DIR"

# Check if Konnect token is set
if [[ -z "${KONNECT_TOKEN}" && ! -f "terraform.tfvars" ]]; then
    echo "❌ Konnect token not found"
    echo "   Please set KONNECT_TOKEN environment variable or create terraform.tfvars"
    echo "   Get your token from: https://cloud.konghq.com → Profile → Personal Access Tokens"
    
fi

# Create outputs directory
mkdir -p outputs
mkdir -p templates

# Create template file if it doesn't exist
if [[ ! -f "templates/connection-details.yaml.tpl" ]]; then
    echo "📝 Creating connection details template..."
    # Template content would be created here
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
cd "$TERRAFORM_DIR"
terraform init

# Validate Terraform configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📝 Planning Terraform deployment..."
terraform plan -out=tfplan

echo "⚠️  About to create Control Plane in Kong Konnect"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    rm -f tfplan
    
fi

# Apply the configuration
echo "🚀 Creating Control Plane..."
terraform apply tfplan

# Display outputs
echo "✅ Control Plane created successfully!"
echo ""
echo "📊 Control Plane Connection Details:"
echo "======================================"

# Get and display key outputs
CP_ID=$(terraform output -raw control_plane_id)
CP_NAME=$(terraform output -raw control_plane_name)
CP_ENDPOINT=$(terraform output -raw control_plane_endpoint)
CLUSTER_SERVER_NAME=$(terraform output -raw cluster_server_name)
TELEMETRY_ENDPOINT=$(terraform output -raw telemetry_endpoint)

echo "Control Plane ID: $CP_ID"
echo "Control Plane Name: $CP_NAME"
echo "Control Plane Endpoint: $CP_ENDPOINT"
echo "Cluster Server Name: $CLUSTER_SERVER_NAME"
echo "Telemetry Endpoint: $TELEMETRY_ENDPOINT"

echo ""
echo "📁 Configuration files created:"
echo "  - outputs/control-plane-$CP_NAME-config.yaml"
echo ""



export KONG_CONTROL_PLANE_ID="$CP_ID"
export KONG_CONTROL_PLANE_NAME="$CP_NAME"
export KONG_CLUSTER_CONTROL_PLANE="$CP_ENDPOINT"
export KONG_CLUSTER_SERVER_NAME="$CLUSTER_SERVER_NAME"
export KONG_CLUSTER_TELEMETRY_ENDPOINT="$TELEMETRY_ENDPOINT"

echo "✅ Control Plane environment variables loaded"
echo "Control Plane: $CP_NAME ($CP_ID)"
EOF

chmod +x "outputs/control-plane-$CP_NAME-env.sh"

# Clean up plan file
rm -f tfplan

echo ""
echo "🎉 Control Plane creation completed!"
echo "   Environment script: outputs/control-plane-$CP_NAME-env.sh"
echo "   Configuration file: outputs/control-plane-$CP_NAME-config.yaml"