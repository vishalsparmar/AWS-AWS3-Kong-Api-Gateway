resource "aws_route53_zone" "pet" {
  name = "pet.example.com"
}

# IAM Role for ExternalDNS with OIDC trust (EKS IRSA)
data "aws_iam_openid_connect_provider" "eks" {
  arn = "arn:aws:iam::<account-id>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/<eks-oidc-id>"
}

resource "aws_iam_role" "externaldns" {
  name = "externaldns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.eks.<region>.amazonaws.com/id/<eks-oidc-id>:sub" = "system:serviceaccount:external-dns:external-dns"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "externaldns" {
  name        = "externaldns-policy"
  description = "Allow ExternalDNS to manage Route53 records"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        Resource = "arn:aws:route53:::hostedzone/${aws_route53_zone.pet.zone_id}"
      },
      {
        Effect   = "Allow",
        Action   = ["route53:ListHostedZones"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "externaldns_attach" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns.arn
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/myapp/db/host"
  type  = "String"
  value = output.db_host.value
}
