# Vault AWS secrets engine

Terraform module for a Vault AWS secrets engine mount. Designed to be instantiated
several times in a single AWS account without the instances interfering with one
another.

## How multi-instance isolation works

The naming of `aws_iam_user` and `aws_iam_policy` was never the real collision
risk — those already carried `var.identifier`. The risk was in the *dynamic* users
the engine creates at runtime.

By default the AWS secrets engine creates IAM users at path `/` with names
starting `vault-`. The original policy granted `iam:DeleteUser`, `iam:PutUserPolicy`
and friends over `arn:aws:iam::ACCOUNT:user/vault-*`, so with two mounts in one
account, mount A's engine could delete or re-policy credentials that mount B had
just issued to somebody.

This module gives each instance its own IAM namespace:

| Object | Location |
| --- | --- |
| Engine identity and policies | `/vault/<identifier>/system/` |
| Dynamically created users | `/vault/<identifier>/dynamic/` |

`user_path` on each role puts dynamic users in the second path, and
`aws_iam_policy.engine` is scoped to exactly that path. The system path sits
*outside* the wildcard, so the engine has no permission to act on its own IAM user
either (unless `allow_root_rotation = true`).

`var.identifier` is validated but uniqueness cannot be enforced by Terraform — two
instances given the same identifier will fight over the same names. Keep it
tied to something already unique in your setup (cluster name, environment, tenant).

## Bugs fixed relative to the previous configuration

- **`iam:AddUserToGroup` / `iam:RemoveUserFromGroup` were unusable.** Those actions
  authorise against the *group* ARN, not the user ARN. Scoped to `user/vault-*`
  they could never match, so any role using `iam_groups` would have failed at
  issuance time. Now scoped to the ARNs of the declared groups.
- **`credential_type` had no default.** The example `roles` value sets only `name`
  and `policy_arns`, so `credential_type` resolved to `null` and the provider
  rejects it. It now defaults to `iam_user`.
- **`aws_account_id` was a hand-passed variable.** Replaced with
  `data.aws_caller_identity`, which also removes the failure mode where a wrong
  account ID produces a policy that silently matches nothing. Partition is read
  from `data.aws_partition` so the module works outside `aws`.
- **The engine's own user was excluded from its policy by accident.** With
  `path = "/system/"` the user ARN is `…:user/system/vault-x`, which
  `user/vault-*` does not match. That was the right outcome for the wrong reason;
  it is now explicit.

## Hardening added

**Attachment is limited to declared policies.** `iam:AttachUserPolicy` was
previously unconstrained, so the engine could attach any managed policy in the
account, `AdministratorAccess` included. It is now conditioned on `iam:PolicyARN`
against exactly the ARNs listed in `var.roles`.

**A permissions boundary is applied to dynamic users.** This closes a concrete
escalation path in your current role set. `admin` carries `IAMFullAccess`, which is
`iam:*` on `*` — so a dynamic admin credential could call `iam:CreateAccessKey` on
`vault-<identifier>` and hold the engine's root credential indefinitely, or attach
`AdministratorAccess` to itself. The boundary denies `iam:*` against
`user/vault/*`, `role/vault/*` and `policy/vault/*`, and (by default) denies
creating principals that do not carry the same boundary.

Be clear-eyed about the limit of this: `PowerUserAccess + IAMFullAccess` is
effectively `AdministratorAccess`, and no boundary changes that. The boundary
protects the *engine* from its own credentials; it does not make the `admin` role
safe to hand out. Restricting it to Vault administrators, as you are doing, is the
actual control.

**Permissions are derived from the declared roles.** If no role uses
`assumed_role`, no `sts:AssumeRole` is granted. If none uses `iam_groups`, no group
actions are granted.

## Choice of `credential_type`

`iam_user` is the default and is correct for your roles. It is worth knowing why
the cheaper options do not apply: credentials from `federation_token` and
`session_token` cannot call the IAM API at all, regardless of the policy attached.
Both of your roles include an IAM policy (`IAMReadOnlyAccess`, `IAMFullAccess`),
so federation tokens would hand out credentials whose IAM permissions silently do
nothing.

The tradeoff you are accepting with `iam_user` is IAM's eventual consistency —
freshly issued keys can take several seconds to become usable, and callers should
retry. If a role only needs non-IAM access, `federation_token` avoids that
entirely and creates no IAM objects.

## The root credential

The static access key remains the default, but note two things about it.

The secret key is stored in plaintext in Terraform state. If Vault runs on EC2 or
EKS, the better option is `create_iam_user = false`: attach the policy exported as
`engine_policy_arn` to the instance profile or IRSA role and let the engine use
ambient credentials. Vault 1.17+ with plugin workload identity federation
(`role_arn` plus an identity token) achieves the same without any static key.

`allow_root_rotation` is available but conflicts with Terraform ownership of the
key. Vault's rotate-root creates a new key and deletes the old one, so
`aws_iam_access_key.engine` in state points at a key that no longer exists;
Terraform will recreate it on the next apply and hand Vault a credential it is not
using. If you want rotation, move to ambient credentials or WIF rather than
enabling this flag.

## Migrating an existing mount

Changing `user_path` and the engine policy's resource ARN affects credentials that
are already outstanding. Users issued under the old path
(`arn:…:user/vault-*`) fall outside the new policy scope, so Vault will fail to
revoke them at lease expiry and they will be left behind in IAM.

Revoke first, then apply:

```sh
vault lease revoke -prefix -sync <old-mount>/creds/
terraform apply
```

Alternatively, add the old ARN pattern to `aws_iam_policy.engine` for one release
so revocation continues to work while existing leases drain, then remove it.

Two other interface changes to be aware of:

- `var.aws_account_id` is gone; remove it from callers.
- `var.mount_path` now defaults to `aws/<identifier>` instead of being required.
  Pass it explicitly to keep an existing path — changing it triggers a remount.

Vault policy names are unchanged (`aws_<identifier>_<role>`) so existing auth
role bindings keep working. Override with `var.vault_policy_name_prefix` or
per-role `vault_policy_name`.

## Usage

```hcl
module "vault_aws_platform" {
  source = "../../modules/se_aws"

  identifier = "platform"
  region     = "eu-central-1"
  mount_path = "aws" # keep the pre-existing path

  default_lease_ttl = 3600
  max_lease_ttl     = 28800

  roles = [
    {
      name = "developer"
      policy_arns = [
        "arn:aws:iam::aws:policy/PowerUserAccess",
        "arn:aws:iam::aws:policy/IAMReadOnlyAccess",
      ]
    },
    {
      name = "admin"
      policy_arns = [
        "arn:aws:iam::aws:policy/PowerUserAccess",
        "arn:aws:iam::aws:policy/IAMFullAccess",
      ]
    },
  ]

  tags = {
    managed-by = "terraform"
  }
}
```

A second instance in the same account needs nothing more than a different
`identifier` and `mount_path`.
