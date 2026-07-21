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

  oidc_role_bindings = merge([
    for role_name, role in var.oidc_roles : (
      length(role.bound_emails) == 0 ? {
        (role_name) = {
          role_name      = role_name
          token_policies = role.token_policies
          token_ttl      = role.token_ttl
          token_max_ttl  = role.token_max_ttl
          bound_email    = null
        }
        } : {
        for email in role.bound_emails :
        "${role_name}--${replace(replace(email, "@", "_at_"), ".", "_")}" => {
          role_name      = "${role_name}--${replace(replace(email, "@", "_at_"), ".", "_")}"
          token_policies = role.token_policies
          token_ttl      = role.token_ttl
          token_max_ttl  = role.token_max_ttl
          bound_email    = email
        }
      }
    )
  ]...)

  oidc_user_bindings = {
    for email, policies in var.oidc_users :
    "user--${replace(replace(email, "@", "_at_"), ".", "_")}" => {
      role_name      = "user--${replace(replace(email, "@", "_at_"), ".", "_")}"
      token_policies = policies
      token_ttl      = 3600
      token_max_ttl  = 14400
      bound_email    = email
    }
  }

  oidc_all_bindings = merge(local.oidc_role_bindings, local.oidc_user_bindings)

  oidc_default_role = coalesce(
    var.oidc_default_role,
    contains(keys(local.oidc_all_bindings), "readonly") ? "readonly" : try(sort(keys(local.oidc_all_bindings))[0], null),
  )

  approle_secret_ids_fixed = {
    for name, role in var.approle_roles :
    name => role.secret_id
    if try(role.secret_id, null) != null && role.secret_id != ""
  }
}
