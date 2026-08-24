# ─── KMS Key for SOPS Secret Encryption ─────────────────────────────────────
# SOPS uses this key to encrypt secret manifests committed to Git.
# ArgoCD's repo-server decrypts them at sync time via Pod Identity.
#
# Lives in its own state, separate from eks-cluster/, on purpose: the EKS
# cluster gets destroyed and recreated, but every secret ever committed to
# Git was encrypted against this exact key. If the key were destroyed and
# recreated alongside the cluster, every *.enc.yaml in the repo would become
# permanently undecryptable (a new key gets a new, unrelated key ID — KMS
# doesn't let you recreate the same key). Keeping it here means an
# eks-cluster rebuild never touches it, and .sops.yaml never goes stale.

resource "aws_kms_key" "secrets" {
  description             = "SOPS encryption key for cluster secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/eks-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}
