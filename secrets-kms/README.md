# secrets-kms

Standalone Terraform module for the SOPS KMS key (`alias/eks-secrets`). Kept
out of `eks-cluster/`'s state on purpose — see the comment at the top of
`main.tf`. Destroying and rebuilding the EKS cluster never touches this.

State: S3 bucket `nahla-terraform-state-686893581621`, key
`secrets-kms/us-west-2/terraform.tfstate` (same bucket/lock table as
`eks-cluster/`, different state file).

## Bootstrap (new AWS account only)

```powershell
terraform -chdir=secrets-kms init
terraform -chdir=secrets-kms apply
terraform -chdir=secrets-kms output kms_key_arn   # paste into .sops.yaml
```

`eks-cluster/` picks up the ARN automatically via `terraform_remote_state` —
no manual wiring needed there.

## Why this exists

Every `secrets/*.enc.yaml` in the repo is encrypted against this specific key.
KMS can't recreate a key with the same ID once destroyed, so if this key ever
lived inside `eks-cluster/`'s state, a routine cluster teardown/rebuild would
silently destroy it, and every encrypted secret in the repo would become
permanently undecryptable — `.sops.yaml` would need a new ARN and every
secret would need re-encrypting from scratch (this happened once already).

`lifecycle.prevent_destroy = true` on `aws_kms_key.secrets` blocks an
accidental `terraform destroy` run from inside this module too.
