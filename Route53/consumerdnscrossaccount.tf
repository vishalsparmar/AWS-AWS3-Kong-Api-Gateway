provider "aws" {
  region = "us-east-1"
}

# Other account provider (read-only to discover the VPC Endpoint DNS)
provider "aws" {
  alias   = "other"
  region  = "us-east-1"
  profile = "other-account-profile"
}

variable "vpc_id" {
  description = "Your VPC ID where the private hosted zone will be associated"
  type        = string
}

# Create a private hosted zone in *your account*
resource "aws_route53_zone" "private" {
  name = "svc.pet.example.com"
  vpc {
    vpc_id = var.vpc_id
  }
  comment = "Private hosted zone for cross-account services"
}

# Lookup the VPC endpoint in the other AWS account
data "aws_vpc_endpoint" "private_svc" {
  provider = aws.other
  id       = "vpce-0abc123456789def0" # replace with actual VPC endpoint ID
}

# Create a record in your hosted zone pointing to the VPC endpoint DNS
resource "aws_route53_record" "private_svc" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.svc.pet.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_vpc_endpoint.private_svc.dns_entry[0].dns_name]
}
