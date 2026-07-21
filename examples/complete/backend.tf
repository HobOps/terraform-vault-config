terraform {
  backend "gcs" {
    bucket = "REPLACE_ME-tfstate"
    prefix = "vault-config/example"
  }
}
