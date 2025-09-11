
# terraform.tfvars.example
# Copy this to terraform.tfvars and fill in your values

# Konnect Authentication
konnect_token      = "spat_FtDhLquCecYSqk1Lr8v4V9fpDiWXL3lYcaOIm3J8kteQnCrhd"
konnect_server_url = "https://eu.api.konghq.com" 

# Control Plane Configuration
control_plane_name        = "vp-gateway"
control_plane_description = "Kong  API Gateway Control Plane"
cluster_type              = "CLUSTER_TYPE_HYBRID"
auth_type                = "pinned_client_certs"
