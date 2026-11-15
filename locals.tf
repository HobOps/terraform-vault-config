locals {
  # Prefer explicit kv_mounts; fall back to legacy single-mount flag/path.
  kv_mounts = length(var.kv_mounts) > 0 ? var.kv_mounts : (
    var.enable_kv_mount ? {
      (var.kv_mount_path) = {
        description = var.kv_mount_description
      }
    } : {}
  )

  default_policies = {
    admin = <<-EOT
      path "*" {
        capabilities = ["create", "read", "update", "delete", "list", "sudo"]
      }
    EOT

    # "+" matches any single path segment (any KV mount: app-dev, team-prod, …).
    ops = <<-EOT
      path "+/data/*" {
        capabilities = ["create", "read", "update", "delete", "list"]
      }
      path "+/metadata/*" {
        capabilities = ["create", "read", "update", "delete", "list"]
      }
      path "+/metadata" {
        capabilities = ["list"]
      }
      path "auth/token/lookup-self" {
        capabilities = ["read"]
      }
      path "auth/token/renew-self" {
        capabilities = ["update"]
      }
      path "sys/policies/acl" {
        capabilities = ["list"]
      }
      path "sys/policies/acl/*" {
        capabilities = ["read"]
      }
    EOT

    readonly = <<-EOT
      path "+/data/*" {
        capabilities = ["read", "list"]
      }
      path "+/metadata/*" {
        capabilities = ["read", "list"]
      }
      path "+/metadata" {
        capabilities = ["list"]
      }
      path "auth/token/lookup-self" {
        capabilities = ["read"]
      }
      path "auth/token/renew-self" {
        capabilities = ["update"]
      }
    EOT

    secrets-ro = <<-EOT
      path "+/data/*" {
        capabilities = ["read"]
      }
      path "+/metadata/*" {
        capabilities = ["read", "list"]
      }
      path "+/metadata" {
        capabilities = ["list"]
      }
    EOT
  }

  policies = {
    for name, policy in merge(
      var.disable_default_policies ? {} : local.default_policies,
      var.policies,
    ) : name => policy if policy != null && policy != ""
  }

  # Email → policies from oidc_roles.bound_emails (open roles handled separately).
  oidc_policies_from_roles = merge(concat(
    [{}],
    [
      for role in values(var.oidc_roles) : {
        for email in role.bound_emails :
        email => role.token_policies
      }
    ],
  )...)

  # Humans with extra policies (Identity). Everyone else can still login via role "default"
  # with only the built-in "default" policy (no secrets).
  oidc_identity_policies = {
    for email in distinct(concat(keys(local.oidc_policies_from_roles), keys(var.oidc_users))) :
    email => distinct(concat(
      lookup(local.oidc_policies_from_roles, email, []),
      lookup(var.oidc_users, email, []),
    ))
  }

  # Open OIDC roles only (bound_emails empty) — still selected by role name at login.
  oidc_open_role_bindings = {
    for role_name, role in var.oidc_roles :
    role_name => {
      role_name      = role_name
      token_policies = role.token_policies
      token_ttl      = role.token_ttl
      token_max_ttl  = role.token_max_ttl
    }
    if length(role.bound_emails) == 0
  }

  oidc_default_role = coalesce(var.oidc_default_role, "default")

  oidc_role_names = compact(concat(
    ["default"],
    sort(keys(local.oidc_open_role_bindings)),
  ))

  approle_secret_ids_fixed = {
    for name, role in var.approle_roles :
    name => role.secret_id
    if try(role.secret_id, null) != null && role.secret_id != ""
  }
}
