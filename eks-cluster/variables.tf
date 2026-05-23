# ─── Cluster ────────────────────────────────────────────────────────────────

variable "cluster_name" {
  description = "Name of the EKS cluster — used across cluster, node group, and subnet tags"
  type        = string
  default     = "my-cluster"
}

# ─── Network ─────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of public subnets to create (one per AZ, max 3 for most regions)"
  type        = number
  default     = 3
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH into worker nodes — restrict to your IP in production"
  type        = string
  default     = "0.0.0.0/0"
}

# ─── Node Group ──────────────────────────────────────────────────────────────

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
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes (for auto-scaling)"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes (for auto-scaling)"
  type        = number
  default     = 6
}
