# Example: complete Vault auth config

Thin wrapper around the root module. Environment-specific values live in
`locals.tf`. Secrets come from a SOPS file pointed to by `local.secrets_file`.

## Prerequisites

- Vault initialized and unsealed; reachable at `local.vault_address`
- `sops`, `terraform`
- OAuth client (Google) with the redirect URIs from `oidc_redirect_uris`

## Setup

1. Copy `secrets.example.yaml` → `secrets.yaml`, fill values, encrypt:
   `sops -e secrets.yaml > secrets.enc.yaml`
2. Edit `locals.tf`, `backend.tf`, and `.sops.yaml` for your environment.
3. Apply:

```bash
cd examples/complete
make init
terraform apply
```

## Login smoke test

```bash
export VAULT_ADDR="$(terraform output -raw vault_address 2>/dev/null || true)"
# or set VAULT_ADDR from locals
vault login -method=oidc role=readonly
```
