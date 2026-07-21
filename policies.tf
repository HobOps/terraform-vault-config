resource "vault_policy" "this" {
  for_each = local.policies

  name   = each.key
  policy = each.value
}
