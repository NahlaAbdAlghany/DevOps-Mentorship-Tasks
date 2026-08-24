output "kms_key_arn" {
  description = "KMS key ARN for SOPS — paste into .sops.yaml, and consumed by eks-cluster/ via terraform_remote_state"
  value       = aws_kms_key.secrets.arn
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.secrets.key_id
}
