# ─── KMS Key for SOPS Secret Encryption ─────────────────────────────────────
# SOPS uses this key to encrypt secret manifests committed to Git.
# ArgoCD's repo-server decrypts them at sync time via Pod Identity — no
# credentials need to be configured explicitly.

resource "aws_kms_key" "secrets" {
  description             = "SOPS encryption key for cluster secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/eks-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}
