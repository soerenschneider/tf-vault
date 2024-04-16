resource "vault_aws_secret_backend_role" "dyndns" {
  backend         = var.aws_secret_backend_path
  name            = "dyndns"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/${var.route53_hosted_zone}"
    }
  ]
}
EOT
}
