# AWS-AWS3-Kong-Api-Gateway
kong api gny TF control plane


Key Points for Getting Connection Details:
Main Outputs You Need:
When you create a control plane with Terraform, these are the essential outputs:

cluster_server_name - The server name for SNI in mTLS connection
telemetry_endpoint - Where data plane sends metrics and telemetry
control_plane_endpoint - Where data plane connects for configuration
cluster_certificate and cluster_certificate_key - For mTLS authentication

