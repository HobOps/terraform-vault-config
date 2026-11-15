# terraform-vault-config

Terraform module that configures HashiCorp Vault auth and secrets mounts for
human SSO (OIDC) and workloads (AppRole). Every component is **off by default**;
enable what you need with `enable_*` flags / `kv_mounts`.

The `vault` provider is configured by the **caller**.

## Components

| Flag / input | Component |
|--------------|-----------|
| `enable_oidc` | OIDC auth backend + roles (e.g. Google Workspace) |
| `enable_approle` | AppRole auth backend + workload roles + secret_ids |
| `kv_mounts` | One or more KV v2 mounts (key = path). Preferred. |
| `enable_kv_mount` | Legacy: single mount at `kv_mount_path` if `kv_mounts` is empty |

ACL policies from `var.policies` are always applied. Built-in defaults
(`admin`, `ops`, `readonly`, `secrets-ro`) are merged in unless
`disable_default_policies = true`. Default secret policies use `+/…` so they
apply to any single-segment KV mount path.

## Usage (Git source)

```hcl
provider "vault" {
  address          = "https://vault.example.com:8200"
  token            = data.sops_file.secrets.data["vault.token"]
  skip_child_token = true
}

module "vault_config" {
  source = "git::https://github.com/HobOps/terraform-vault-config.git?ref=v0.1.0"

  enable_oidc    = true
  enable_approle = true

  kv_mounts = {
    "app-dev"  = { description = "Application development secrets" }
    "app-prod" = { description = "Application production secrets" }
  }

  oidc_client_id     = data.sops_file.secrets.data["google_oidc.client_id"]
  oidc_client_secret = data.sops_file.secrets.data["google_oidc.client_secret"]
  oidc_hosted_domain = "example.com"
  oidc_redirect_uris = [
    "https://vault.example.com:8200/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]

  # Domain users log in with Role blank (default = no secrets).
  # Extra access: Identity via oidc_users / oidc_roles.bound_emails.
  oidc_roles = {
    admin = {
      token_policies = ["admin"]
      bound_emails   = ["alice@example.com"]
    }
  }

  oidc_users = {
    "bob@example.com" = ["ops"]
  }

  policies = {
    app-dev-read = <<-EOT
      path "app-dev/data/*" {
        capabilities = ["read"]
      }
      path "app-dev/metadata/*" {
        capabilities = ["read", "list"]
      }
      path "app-dev/metadata" {
        capabilities = ["list"]
      }
    EOT
  }

  approle_roles = {
    app-gke = {
      token_policies = ["app-dev-read"]
      cidr_list      = ["203.0.113.10/32"]
    }
  }
}
```

See [`examples/complete`](examples/complete) for a full thin wrapper (providers, SOPS, backend).

## Human login (OIDC)

```bash
export VAULT_ADDR=https://vault.example.com:8200
vault login -method=oidc role=readonly
```

## Workload login (AppRole)

```bash
vault write auth/approle/login \
  role_id="$ROLE_ID" \
  secret_id="$SECRET_ID"
```

Role IDs and secret IDs are exposed as module outputs (`approle_role_ids`,
`approle_secret_ids`).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| vault | >= 4.0, < 6 |

## Repository layout

```
.
├── *.tf                 # root module (Registry-compatible)
├── examples/complete/   # example caller stack
├── LICENSE
└── README.md
```

## Versioning

Tag releases with semver (`v0.1.0`, `v1.0.0`, …) so callers can pin `?ref=`
and so the Terraform Registry can publish versions later.
