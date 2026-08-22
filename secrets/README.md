# Secrets

Cluster secrets are encrypted with [SOPS](https://github.com/getsops/sops) using AWS KMS and stored directly in Git. ArgoCD decrypts them at sync time through [ksops](https://github.com/viaduct-ai/kustomize-sops) — no secrets leave the cluster, no Secrets Manager cost per secret.

## How it works

```
Plain Secret (local only)
        │
        ▼
  sops --encrypt (KMS)
        │
        ▼
  *.enc.yaml ──► Git ──► ArgoCD (ksops plugin)
                                  │
                          KMS Decrypt via Pod Identity
                                  │
                          plain Secret in cluster
```

- **`*.enc.yaml`** — AES256-GCM encrypted, safe to commit; KMS holds the data key
- **Plain YAML** — never committed; create and discard locally

## Architecture

| Component | Role |
|---|---|
| `aws_kms_key.secrets` (`alias/eks-secrets`) | Master key; never leaves AWS HSM |
| `ArgoCDRepoServerRole` | IAM role granted `kms:Decrypt` — assumed by `argocd-repo-server` via Pod Identity |
| SOPS v3.9.0 | Encrypts/decrypts secret files using the KMS key |
| ksops | Kustomize exec plugin — called by ArgoCD at sync time to decrypt `*.enc.yaml` |

## Prerequisites

| Tool | Install |
|---|---|
| `sops` v3.9.0 | `$env:LOCALAPPDATA\Programs\sops\sops.exe` |
| `kubectl` | connected to the cluster |
| AWS credentials | with `kms:Encrypt` + `kms:GenerateDataKey` on `alias/eks-secrets` |

## Secrets in this directory

| File | Secret name | Namespace | Keys |
|---|---|---|---|
| `grafana-admin-secret.enc.yaml` | `grafana-admin-secret` | `monitoring` | `admin-user`, `admin-password` |
| `gitea-admin-secret.enc.yaml` | `gitea-admin-secret` | `gitea` | `username`, `password` |

## Adding a new secret

### 1. Create the plain secret locally (never commit this)

```powershell
kubectl create secret generic <secret-name> `
  --namespace <namespace> `
  --from-literal=<key>=<value> `
  --dry-run=client -o yaml `
  | Out-File -Encoding utf8 secrets\<secret-name>.enc.yaml
```

### 2. Encrypt it in place

```powershell
& "$env:LOCALAPPDATA\Programs\sops\sops.exe" --encrypt --in-place secrets\<secret-name>.enc.yaml
```

### 3. Register it in the ksops generator

```yaml
# secrets/ksops.yaml
files:
  - ./grafana-admin-secret.enc.yaml
  - ./<secret-name>.enc.yaml      # add this line
```

### 4. Commit and push

```powershell
git add secrets\<secret-name>.enc.yaml secrets\ksops.yaml
git commit -m "feat(secrets): encrypt <secret-name>"
git push
```

ArgoCD picks up the change, ksops decrypts via KMS, and the plain Secret appears in the target namespace.

## Rotating a secret

1. Decrypt the current file:
   ```powershell
   & "$env:LOCALAPPDATA\Programs\sops\sops.exe" --decrypt --in-place secrets\<secret-name>.enc.yaml
   ```
2. Edit the plaintext values directly in the file
3. Re-encrypt:
   ```powershell
   & "$env:LOCALAPPDATA\Programs\sops\sops.exe" --encrypt --in-place secrets\<secret-name>.enc.yaml
   ```
4. Commit and push — ArgoCD re-syncs, the updated Secret is applied

## Key management

The KMS key is managed in Terraform (`eks-cluster/modules/eks/kms.tf`):
- **Key rotation**: enabled (AWS rotates the backing key material annually)
- **Deletion window**: 30 days (gives time to cancel an accidental key deletion)
- **Access**: scoped to `argocd-repo-server` for decrypt; developers need `kms:Encrypt` + `kms:GenerateDataKey` locally

To get the key ARN after `terraform apply`:
```powershell
terraform -chdir=eks-cluster output sops_kms_key_arn
```

## SOPS configuration

`.sops.yaml` at the repo root controls which KMS key is used per path:

```yaml
creation_rules:
  - path_regex: .*\.enc\.yaml$
    kms: arn:aws:kms:us-west-2:<account>:key/<key-id>
```

All files matching `*.enc.yaml` anywhere in the repo will be encrypted with this key.
