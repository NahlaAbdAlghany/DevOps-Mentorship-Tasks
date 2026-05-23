# ─── EKS Cluster ─────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn # managed in IAM.tf — no hardcoded ARN
  version  = "1.33"

  vpc_config {
    subnet_ids = var.subnet_ids

    # endpoint_private_access: nodes communicate with the control plane over a private
    #   endpoint inside the VPC — traffic stays within AWS, not over the internet.
    # endpoint_public_access: keeps the kubectl API reachable from outside the VPC.
    #   In production with a VPN/bastion, set this to false.
    endpoint_private_access = true
    endpoint_public_access  = true
  }
  bootstrap_self_managed_addons = false
  # Control plane log types sent to CloudWatch Logs.
  # api:           all kubectl requests to the API server
  # audit:         who did what to which resource (important for security)
  # authenticator: IAM authentication events (useful for debugging auth failures)
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  # Ensure the cluster role and its policy are fully attached before creating the cluster.
  # Without this, the cluster creation can fail with an IAM propagation error.
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# ─── EKS Addons ──────────────────────────────────────────────────────────────

# Standard addons that don't need a dedicated IAM role (no IRSA)
resource "aws_eks_addon" "addons" {
  for_each = local.eks_addons

  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = each.key

  # OVERWRITE lets Terraform re-apply addon config even if it was changed outside Terraform
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # coredns and aws-ebs-csi-driver are Deployments that need nodes to schedule on.
  # Wait for both node groups to be ready before creating any addon.
  depends_on = [
    aws_eks_node_group.nodes,
    aws_eks_node_group.argocd,
  ]
}

# ─── Pod Identity Associations ───────────────────────────────────────────────
# Pod Identity replaces IRSA: the eks-pod-identity-agent DaemonSet intercepts
# credential requests from pods and returns STS credentials for the associated
# IAM role — no OIDC provider or token projection needed.

resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_role.arn
}

resource "aws_eks_pod_identity_association" "cert_manager" {
  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = "cert-manager"
  service_account = "cert-manager"
  role_arn        = aws_iam_role.cert_manager_role.arn
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler_role.arn
}




