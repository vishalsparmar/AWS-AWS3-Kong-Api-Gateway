provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias   = "other"
  region  = "us-east-1"
  profile = "other-account-profile"
}

resource "aws_route53_zone" "pet" {
  name = "pet.example.com"
}

# Kong NLB
data "aws_lb" "kong" {
  name = "k8s-kong-proxy-xxxx"
}

resource "aws_route53_record" "kong" {
  zone_id = aws_route53_zone.pet.zone_id
  name    = "kong.pet.example.com"
  type    = "A"

  alias {
    name                   = data.aws_lb.kong.dns_name
    zone_id                = data.aws_lb.kong.zone_id
    evaluate_target_health = true
  }
}

# VPC Endpoint in other account
data "aws_vpc_endpoint" "private_svc" {
  provider = aws.other
  id       = "vpce-1234567890abcdef"
}

resource "aws_route53_record" "private_service" {
  zone_id = aws_route53_zone.pet.zone_id
  name    = "internal.pet.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_vpc_endpoint.private_svc.dns_entry[0].dns_name]
}
