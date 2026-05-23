# ─── Launch Template ─────────────────────────────────────────────────────────
# Shared by both node groups. Enforces IMDSv2 with hop_limit=2 so that
# containers running on the node can reach the metadata service (the default
# hop_limit=1 drops the request after the first IP hop, breaking IRSA inside
# pods). remote_access is replaced by key_name here because the two blocks
# are mutually exclusive on EKS managed node groups.
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.cluster_name}-nodes-"

  key_name = "eks-cluster"

  # When vpc_security_group_ids is set in a launch template, AWS does NOT
  # automatically attach the EKS cluster security group — it must be listed
  # explicitly here alongside any additional groups (e.g. the SSH SG).
  vpc_security_group_ids = [
    aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id,
    var.node_ssh_security_group_id,
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only — blocks unauthenticated v1 calls
    http_put_response_hop_limit = 2          # allows one container-to-host hop
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── General Worker Node Group ───────────────────────────────────────────────
resource "aws_eks_node_group" "nodes" {
  cluster_name    = var.cluster_name
  node_group_name = "worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn # managed in IAM.tf — no hardcoded ARN
  subnet_ids      = var.subnet_ids

  # Auto-scaling boundaries — desired_size is the initial count.
  # The Cluster Autoscaler (if installed) adjusts within min/max based on pod demand.
  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  capacity_type  = var.capacity_type
  instance_types = var.instance_types

  # Cluster Autoscaler discovers managed node groups via these tags on the
  # underlying ASG. Both tags must be present for auto-discovery to work.
  tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
  }

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  # Wait for the cluster and all node role policies to be fully ready before
  # creating nodes. IAM changes take a few seconds to propagate globally;
  # without this, node registration can fail with permission errors.
  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_launch_template.eks_nodes,
  ]
}

# ─── ArgoCD Dedicated Node Group ─────────────────────────────────────────────
# ON_DEMAND only — ArgoCD drives all GitOps syncs; a spot interruption would
# stall deployments across every app until the node is replaced.
resource "aws_eks_node_group" "argocd" {
  cluster_name    = var.cluster_name
  node_group_name = "argocd-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.argocd_desired_size
    min_size     = var.argocd_min_size
    max_size     = var.argocd_max_size
  }

  capacity_type  = "ON_DEMAND"
  instance_types = [var.argocd_instance_type]

  # Label lets ArgoCD pods target this group via nodeSelector.
  labels = {
    role = "argocd"
  }

  # Taint repels every pod that doesn't explicitly tolerate it,
  # so general workloads never land on ArgoCD nodes.
  taint {
    key    = "dedicated"
    value  = "argocd"
    effect = "NO_SCHEDULE"
  }

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_launch_template.eks_nodes,
  ]
}
