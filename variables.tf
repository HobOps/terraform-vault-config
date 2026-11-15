# --- Feature flags (all off by default) ---

variable "enable_oidc" {
  description = "Configure OIDC auth backend (e.g. Google Workspace SSO for humans)."
  type        = bool
  default     = false
}

variable "enable_approle" {
  description = "Configure AppRole auth backend for workloads."
  type        = bool
  default     = false
}

variable "enable_kv_mount" {
  description = <<-EOT
    Legacy flag: when true and kv_mounts is empty, creates a single KV v2 mount
    at kv_mount_path. Prefer kv_mounts for one or more mounts.
  EOT
  type        = bool
  default     = false
}

# --- Policies ---

variable "policies" {
  description = <<-EOT
    Map of Vault ACL policy name → HCL policy body.
    Merged with module defaults (admin, ops, readonly, secrets-ro) unless
    disable_default_policies is true. Empty string values are skipped.
  EOT
  type        = map(string)
  default     = {}
}

variable "disable_default_policies" {
  description = "If true, only var.policies are applied (no built-in admin/ops/readonly/secrets-ro)."
  type        = bool
  default     = false
}

# --- KV mounts ---

variable "kv_mounts" {
  description = <<-EOT
    KV v2 mounts to create. Key = mount path (e.g. app-dev).
    When non-empty, these mounts are created (enable_kv_mount is ignored).
    When empty and enable_kv_mount=true, falls back to kv_mount_path.
  EOT
  type = map(object({
    description = optional(string)
  }))
  default = {}
}

variable "kv_mount_path" {
  description = "Legacy single KV mount path used only when enable_kv_mount=true and kv_mounts is empty."
  type        = string
  default     = "secrets"
}

variable "kv_mount_description" {
  description = "Legacy description for the single KV mount (enable_kv_mount fallback)."
  type        = string
  default     = "Application secrets"
}

# --- OIDC ---

variable "oidc_path" {
  description = "Mount path for the OIDC auth backend."
  type        = string
  default     = "oidc"
}

variable "oidc_discovery_url" {
  description = "OIDC discovery URL (Google Workspace: https://accounts.google.com)."
  type        = string
  default     = "https://accounts.google.com"
}

variable "oidc_bound_issuer" {
  description = "Expected issuer claim (Google: https://accounts.google.com)."
  type        = string
  default     = "https://accounts.google.com"
}

variable "oidc_client_id" {
  description = "OIDC client ID. Required when enable_oidc is true."
  type        = string
  default     = null
  sensitive   = true
}

variable "oidc_client_secret" {
  description = "OIDC client secret. Required when enable_oidc is true."
  type        = string
  default     = null
  sensitive   = true
}

variable "oidc_hosted_domain" {
  description = "Google Workspace domain enforced via OIDC claim `hd`."
  type        = string
  default     = null
}

variable "oidc_redirect_uris" {
  description = "Allowed OIDC redirect URIs (Vault UI + CLI localhost callback)."
  type        = list(string)
  default     = []
}

variable "oidc_default_role" {
  description = "Default OIDC role name. Null = first role from oidc_roles/oidc_users bindings."
  type        = string
  default     = null
}

variable "oidc_roles" {
  description = <<-EOT
    OIDC roles. Key = role name.
    bound_emails empty → open named role (any user matching hd); selected by role name.
    bound_emails non-empty → those emails get token_policies via Identity entities
    (they still log in with Role blank / "default").
  EOT
  type = map(object({
    token_policies = list(string)
    token_ttl      = optional(number, 3600)
    token_max_ttl  = optional(number, 14400)
    bound_emails   = optional(list(string), [])
  }))
  default = {}
}

variable "oidc_users" {
  description = <<-EOT
    Extra policies for specific emails (Identity entities).
    All @hosted_domain users can log in with Role blank; without an entry here they
    only get Vault's built-in "default" policy (no secrets).
  EOT
  type        = map(list(string))
  default     = {}
}

variable "oidc_scopes" {
  description = "OIDC scopes requested during login."
  type        = list(string)
  default     = ["openid", "email", "profile"]
}

variable "oidc_default_lease_ttl" {
  description = "Default lease TTL for the OIDC auth backend."
  type        = string
  default     = "1h"
}

variable "oidc_max_lease_ttl" {
  description = "Max lease TTL for the OIDC auth backend."
  type        = string
  default     = "6h"
}

# --- AppRole ---

variable "approle_path" {
  description = "Mount path for the AppRole auth backend."
  type        = string
  default     = "approle"
}

variable "approle_roles" {
  description = <<-EOT
    AppRole roles for workloads. Key = role name.
    secret_id: optional fixed secret_id; omit/null to let Vault generate one.
  EOT
  type = map(object({
    token_policies = list(string)
    token_ttl      = optional(number, 3600)
    token_max_ttl  = optional(number, 21600)
    secret_id_ttl  = optional(number, 0)
    cidr_list      = optional(list(string), [])
    secret_id      = optional(string, null)
  }))
  default = {}
}

variable "approle_default_lease_ttl" {
  description = "Default lease TTL for the AppRole auth backend."
  type        = string
  default     = "1h"
}

variable "approle_max_lease_ttl" {
  description = "Max lease TTL for the AppRole auth backend."
  type        = string
  default     = "6h"
}
