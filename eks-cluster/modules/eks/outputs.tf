output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "API server endpoint — use this to configure kubectl or other tools"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data — needed for kubectl kubeconfig"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cert_manager_role_arn" {
  description = "IAM Role ARN for cert-manager DNS-01 — share this with GCP as the trusted STS principal"
  value       = aws_iam_role.cert_manager_role.arn
}

output "node_group_name" {
  description = "EKS node group name"
  value       = aws_eks_node_group.nodes.node_group_name
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.nodes.arn
}
