resource "vault_mount" "kv" {
  for_each = local.kv_mounts

  path        = each.key
  type        = "kv"
  options     = { version = "2" }
  description = coalesce(each.value.description, "KV v2 secrets (${each.key})")
}
