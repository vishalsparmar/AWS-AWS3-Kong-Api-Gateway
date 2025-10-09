# Install required tools
sudo apt-get install jq yq curl  # On Ubuntu

# Set your Konnect token
export KONNECT_TOKEN="your-personal-access-token"
Run the deployment:

bash
# Make script executable
chmod +x konnect-create-services-routes.sh

# Run with config file
./konnect-create-services-routes.sh kong-config.yaml

# Or with custom config
./konnect-create-services-routes.sh my-services.yaml
