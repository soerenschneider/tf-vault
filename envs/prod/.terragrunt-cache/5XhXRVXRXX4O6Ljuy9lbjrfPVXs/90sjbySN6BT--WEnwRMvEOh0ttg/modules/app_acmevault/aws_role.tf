locals {
  # zone_id => ["_acme-challenge.<d>", "_acme-challenge.*.<d>", ...]
  acmevault_challenge_names = {
    for zone_id, domains in var.acmevault_zones :
    zone_id => flatten([
      for d in domains : [
        "_acme-challenge.${d}",
        "_acme-challenge.*.${d}",
      ]
    ])
  }

  acmevault_zone_arns = [
    for zone_id in keys(var.acmevault_zones) :
    "arn:aws:route53:::hostedzone/${zone_id}"
  ]

  acmevault_change_statements = [
    for zone_id, names in local.acmevault_challenge_names : {
      Sid      = "AcmeChallenge${zone_id}"
      Effect   = "Allow"
      Action   = "route53:ChangeResourceRecordSets"
      Resource = "arn:aws:route53:::hostedzone/${zone_id}"
      Condition = {
        "ForAllValues:StringLike" = {
          "route53:ChangeResourceRecordSetsNormalizedRecordNames" = names
        }
        "ForAllValues:StringEquals" = {
          "route53:ChangeResourceRecordSetsRecordTypes" = ["TXT"]
          "route53:ChangeResourceRecordSetsActions"     = var.acmevault_allowed_actions
        }
        Null = {
          "route53:ChangeResourceRecordSetsNormalizedRecordNames" = "false"
          "route53:ChangeResourceRecordSetsRecordTypes"           = "false"
          "route53:ChangeResourceRecordSetsActions"               = "false"
        }
      }
    }
  ]

  acmevault_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      local.acmevault_change_statements,
      [
        {
          Sid    = "ReadRecordsAndChanges"
          Effect = "Allow"
          Action = [
            "route53:GetChange",
            "route53:ListResourceRecordSets",
          ]
          Resource = concat(
            local.acmevault_zone_arns,
            ["arn:aws:route53:::change/*"],
          )
        },
        {
          Sid      = "ZoneLookup"
          Effect   = "Allow"
          Action   = "route53:ListHostedZonesByName"
          Resource = "*"
        },
      ],
    )
  })
}

resource "vault_aws_secret_backend_role" "acmevault" {
  backend         = var.aws_path
  name            = "acmevault"
  credential_type = "iam_user"
  policy_document = local.acmevault_policy
}