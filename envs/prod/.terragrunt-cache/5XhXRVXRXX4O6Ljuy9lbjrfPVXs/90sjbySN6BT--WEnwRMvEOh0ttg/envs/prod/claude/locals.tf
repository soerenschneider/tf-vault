data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  iam_prefix = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}"
  sts_prefix = "arn:${data.aws_partition.current.partition}:sts::${data.aws_caller_identity.current.account_id}"

  # Every AWS object this instance owns lives under an identifier-scoped IAM path.
  # This is what makes several instances of the module safe in one account: the
  # engine's policy is scoped to its own path, so it cannot see, re-policy or
  # delete credentials belonging to another instance.
  #
  # system_path holds the engine's own identity and is deliberately NOT covered by
  # the dynamic_path wildcard, so the engine cannot act on itself.
  system_path  = "/vault/${var.identifier}/system/"
  dynamic_path = "/vault/${var.identifier}/dynamic/"

  name_prefix = "vault-${var.identifier}"

  mount_path         = coalesce(var.mount_path, "aws/${var.identifier}")
  policy_name_prefix = coalesce(var.vault_policy_name_prefix, "aws_${var.identifier}_")

  dynamic_user_arn = "${local.iam_prefix}:user${local.dynamic_path}*"
  system_user_arn  = "${local.iam_prefix}:user${local.system_path}${local.name_prefix}"

  roles          = { for r in var.roles : r.name => r }
  iam_user_roles = { for k, r in local.roles : k => r if r.credential_type == "iam_user" }

  # Only grant the permissions the declared roles actually need.
  uses_iam_user   = length(local.iam_user_roles) > 0
  uses_federation = anytrue([for r in var.roles : r.credential_type == "federation_token"])
  uses_session    = anytrue([for r in var.roles : r.credential_type == "session_token"])

  assumable_role_arns = distinct(flatten([
    for r in var.roles : coalesce(r.role_arns, []) if r.credential_type == "assumed_role"
  ]))

  # The exact set of managed policies the engine is allowed to attach. Anything
  # not declared here (AdministratorAccess, for example) is unattachable.
  attachable_policy_arns = distinct(flatten([
    for r in local.iam_user_roles : coalesce(r.policy_arns, [])
  ]))

  managed_group_names = distinct(flatten([
    for r in local.iam_user_roles : coalesce(r.iam_groups, [])
  ]))

  # iam:AddUserToGroup authorises against the GROUP arn, not the user arn. Group
  # names are accepted without a path, so allow both the root path and one level
  # of nesting.
  managed_group_arns = flatten([
    for g in local.managed_group_names : [
      "${local.iam_prefix}:group/${g}",
      "${local.iam_prefix}:group/*/${g}",
    ]
  ])

  # ---------------------------------------------------------------------------
  # Permissions boundary resolution
  # ---------------------------------------------------------------------------
  boundary_name = "${local.name_prefix}-dynamic-boundary"

  # Built by hand rather than referenced, so the boundary document can name itself
  # without creating a dependency cycle.
  boundary_arn = "${local.iam_prefix}:policy${local.system_path}${local.boundary_name}"

  role_boundary_arn = {
    for k, r in local.iam_user_roles : k => (
      r.permissions_boundary_arn != null
      ? (r.permissions_boundary_arn == "" ? null : r.permissions_boundary_arn)
      : (var.create_permissions_boundary ? local.boundary_arn : null)
    )
  }

  allowed_boundary_arns = distinct([for arn in values(local.role_boundary_arn) : arn if arn != null])

  # The iam:PermissionsBoundary condition can only be enforced on CreateUser if
  # every iam_user role carries a boundary; otherwise unbounded roles would break.
  enforce_boundary_on_create = (
    local.uses_iam_user &&
    length(local.allowed_boundary_arns) > 0 &&
    length([for arn in values(local.role_boundary_arn) : arn if arn == null]) == 0
  )
}
