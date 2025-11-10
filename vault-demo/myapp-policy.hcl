# Access to read/write secret data
path "secret/data/mysql" {
  capabilities = ["create", "update", "read", "delete", "list"]
}
path "secret/data/frontend" {
  capabilities = ["create", "update", "read", "delete", "list"]
}
# Access to list secrets under the path
path "secret/metadata/mysql" {
  capabilities = ["list"]
}
path "secret/metadata/frontend" {
  capabilities = ["list"]
}
