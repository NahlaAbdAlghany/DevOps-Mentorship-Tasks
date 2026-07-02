# Sealed Secrets

Cluster secrets are encrypted with [Bitnami Sealed Secrets](https://github.com/bitnami/sealed-secrets) v0.38.1 and stored directly in Git. The in-cluster controller holds the private key and is the only entity that can decrypt them.

## How it works

```
Plain Secret (local only)
        │
        ▼
   kubeseal + public cert
        │
        ▼
 SealedSecret YAML ──► Git ──► ArgoCD ──► cluster
                                              │
                                    sealed-secrets controller
                                    decrypts → plain Secret
```

- **SealedSecret** — safe to commit; encrypted with the controller's public key
- **Plain Secret / `.pem` cert** — never committed; covered by `.gitignore`

## Prerequisites

| Tool | Install |
|---|---|
| `kubectl` | connected to the cluster |
| `kubeseal` v0.38.1 | `$env:LOCALAPPDATA\Programs\kubeseal\kubeseal.exe` |

## ArgoCD deployment

| App | Wave | What it deploys |
|---|---|---|
| `sealed-secrets-app.yaml` | 0 | Sealed Secrets controller (Helm chart 2.19.0) into `kube-system` |
| `sealed-secrets-config-app.yaml` | 1 | All `*.yaml` files in this directory into `monitoring` |

Wave 0 must be healthy before wave 1 runs — ArgoCD enforces this automatically.

## Sealing a new secret

### 1. Fetch the controller's public cert (once per cluster)

```powershell
# Run from the repo root
& "$env:LOCALAPPDATA\Programs\kubeseal\kubeseal.exe" --fetch-cert `
  --controller-name=sealed-secrets-controller `
  --controller-namespace=kube-system `
  | Out-File -Encoding utf8 sealed-secrets\sealed-secrets-pub.pem
```

> The `.pem` file is gitignored. Keep it locally — you only need to re-fetch it if the controller's key is rotated.

### 2. Create the plain secret (never commit this file)

```powershell
kubectl create secret generic <secret-name> `
  --namespace <namespace> `
  --from-literal=<key>=<value> `
  --dry-run=client -o yaml `
  | Out-File -Encoding utf8 sealed-secrets\<secret-name>-raw.yaml
```

> `*-raw.yaml` files are gitignored.

### 3. Seal it

```powershell
& "$env:LOCALAPPDATA\Programs\kubeseal\kubeseal.exe" `
  --cert sealed-secrets\sealed-secrets-pub.pem `
  --format yaml `
  < sealed-secrets\<secret-name>-raw.yaml `
  > sealed-secrets\<secret-name>.yaml
```

### 4. Commit and push

```powershell
git add sealed-secrets\<secret-name>.yaml
git commit -m "feat(secrets): seal <secret-name>"
git push
```

ArgoCD picks up the new `SealedSecret`, the controller decrypts it, and the plain `Secret` appears in the target namespace.

> **PowerShell encoding warning** — always use `| Out-File -Encoding utf8` or the Bash tool when writing files that kubeseal reads. PowerShell's `>` operator writes UTF-16 LE, which kubeseal rejects with `data does not contain any valid RSA or ECDSA certificates`.

## Secrets in this directory

| File | Secret name | Namespace | Keys |
|---|---|---|---|
| `grafana-sealed-secret.yaml` | `grafana-admin-secret` | `monitoring` | `admin-user`, `admin-password` |

## Rotating a secret

1. Update the plain secret file (`*-raw.yaml`) with the new value
2. Re-run step 3 above to re-seal it (overwrites the old `.yaml`)
3. Commit and push
4. Restart the consuming pod to pick up the new value:
   ```powershell
   kubectl rollout restart deployment/<name> -n <namespace>
   ```

## Key backup

The controller auto-generates an RSA key pair on first start and stores it as a Secret in `kube-system`:

```powershell
# Backup the key (store securely, NOT in Git)
kubectl get secret -n kube-system `
  -l sealedsecrets.bitnami.com/sealed-secrets-key `
  -o yaml > sealed-secrets-master-key-backup.yaml
```

If the cluster is lost and you restore this key before the controller starts, all existing SealedSecrets will decrypt correctly. Without it, all SealedSecrets must be re-sealed.
