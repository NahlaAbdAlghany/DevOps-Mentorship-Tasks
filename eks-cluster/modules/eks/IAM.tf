# ─── EKS Cluster Role ────────────────────────────────────────────────────────
# The EKS control plane assumes this role to manage AWS resources on your behalf
# (e.g. creating ENIs in your VPC, describing EC2 instances).

resource "aws_iam_role" "eks_cluster_role" {
  name = "eksClusterRole"

  # Trust policy: only the EKS service can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Grants the cluster role the minimum permissions required to run EKS
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ─── EKS Node Role ───────────────────────────────────────────────────────────
# Worker nodes (EC2 instances) assume this role to interact with AWS services:
#   - pulling images from ECR
#   - attaching ENIs for pod networking (VPC CNI)
#   - reading cluster info

resource "aws_iam_role" "eks_node_role" {
  name = "AmazonEKSNodeRole"

  # Trust policy: only EC2 instances can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Allows nodes to connect to the EKS cluster and register themselves
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Allows the VPC CNI plugin to allocate IPs for pods from the VPC CIDR
resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Allows nodes to pull container images from ECR (Elastic Container Registry)
resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ─── EBS CSI Role ────────────────────────────────────────────────────────────
# Pod Identity: the eks-pod-identity-agent assumes this role on behalf of the
# ebs-csi-controller-sa service account. The association is defined in eks.tf.

resource "aws_iam_role" "ebs_csi_role" {
  name = "AmazonEKS_EBS_CSI_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

# Grants the EBS CSI role permissions to create, attach, and delete EBS volumes
resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ─── cert-manager Role (DNS-01 via GCP Workload Identity Federation) ──────────
# Pod Identity: the eks-pod-identity-agent assumes this role on behalf of the
# cert-manager service account. The role has no AWS permissions — its sole purpose
# is to produce an STS token that cert-manager exchanges with GCP STS for a GCP
# access token, used to create DNS-01 TXT records in GCP Cloud DNS.
# The association is defined in eks.tf.
#
# NOTE: remove AWS_ROLE_ARN / AWS_WEB_IDENTITY_TOKEN_FILE from the cert-manager
# Helm/ArgoCD values — those are IRSA-specific. Pod Identity injects credentials
# automatically via the agent; no env vars are needed.

resource "aws_iam_role" "cert_manager_role" {
  name = "cert-manager-dns01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

# ─── Cluster Autoscaler Role ──────────────────────────────────────────────────
# Pod Identity: the eks-pod-identity-agent assumes this role on behalf of the
# cluster-autoscaler service account in kube-system. The association is in eks.tf.

resource "aws_iam_role" "cluster_autoscaler_role" {
  name = "ClusterAutoscalerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "cluster_autoscaler_policy" {
  name = "ClusterAutoscalerPolicy"
  role = aws_iam_role.cluster_autoscaler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      }
    ]
  })
}
