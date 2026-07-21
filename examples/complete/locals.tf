locals {
  vault_address  = "https://vault.example.com:8200"
  vault_hostname = "vault.example.com"

  # Path to a SOPS-encrypted secrets file.
  secrets_file = "secrets.enc.yaml"

  oidc_hosted_domain = "example.com"

  oidc_redirect_uris = [
    "https://${local.vault_hostname}:8200/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]

  # Feature flags (module defaults are false; enable what this Vault needs).
  enable_oidc    = true
  enable_approle = true

  kv_mounts = {
    "app-dev"  = { description = "Application development secrets" }
    "app-prod" = { description = "Application production secrets" }
  }

  oidc_roles = {
    admin = {
      token_policies = ["admin"]
      bound_emails   = ["alice@example.com"]
    }
    ops = {
      token_policies = ["ops"]
      bound_emails   = []
    }
    readonly = {
      token_policies = ["readonly"]
      bound_emails   = []
    }
  }

  oidc_users = {
    # "bob@example.com" = ["ops"]
  }

  approle_roles = {
    app-gke = {
      token_policies = ["secrets-ro"]
      token_ttl      = 3600
      token_max_ttl  = 21600
      secret_id_ttl  = 0
      cidr_list      = ["203.0.113.10/32"]
    }
  }

  # Extra / override policies (merged with module defaults).
  policies = {
    # "app-dev-read" = <<-EOT
    #   path "app-dev/data/*" {
    #     capabilities = ["read"]
    #   }
    #   path "app-dev/metadata/*" {
    #     capabilities = ["read", "list"]
    #   }
    #   path "app-dev/metadata" {
    #     capabilities = ["list"]
    #   }
    # EOT
  }
}
