variable "subnet_ids" {
  description = "List of subnet IDs where the EKS control plane ENIs and worker nodes are placed"
  type        = list(string)
}

variable "sops_kms_key_arn" {
  description = "ARN of the SOPS KMS key (managed in ../../../secrets-kms), granted to the ArgoCD repo-server role for decrypt"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-cluster"
}

variable "node_ssh_security_group_id" {
  description = "Security group ID attached to worker nodes to allow SSH from ssh_cidr"
  type        = string
}

# ─── Node Group Sizing ────────────────────────────────────────────────────────

variable "capacity_type" {
  description = "Capacity type for worker nodes: SPOT or ON_DEMAND"
  type        = string
  default     = "SPOT"
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes. Multiple types improve spot availability."
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t2.medium"]
}

# ─── ArgoCD Node Group ───────────────────────────────────────────────────────

variable "argocd_instance_type" {
  description = "EC2 instance type for the ArgoCD-dedicated node group"
  type        = string
  default     = "t3.medium"
}

variable "argocd_desired_size" {
  description = "Desired number of ArgoCD nodes"
  type        = number
  default     = 3
}

variable "argocd_min_size" {
  description = "Minimum number of ArgoCD nodes"
  type        = number
  default     = 3
}

variable "argocd_max_size" {
  description = "Maximum number of ArgoCD nodes"
  type        = number
  default     = 5
}

# ─── Worker Node Group Sizing ─────────────────────────────────────────────────

variable "desired_size" {
  description = "Initial number of worker nodes to launch"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes (lower bound for auto-scaling)"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes (upper bound for auto-scaling)"
  type        = number
  default     = 3
}
