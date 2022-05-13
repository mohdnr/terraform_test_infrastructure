###
# AWS EKS Cluster configuration
###

locals {
  cluster_name = "security-tools"
}

resource "aws_eks_cluster" "security_tools" {
  name     = local.cluster_name
  role_arn = aws_iam_role.security_tools_role.arn
  version  = var.cluster_version

  enabled_cluster_log_types = ["api", "audit", "controllerManager", "scheduler", "authenticator"]

  vpc_config {
    security_group_ids = [
      aws_security_group.security_tools_worker.id
    ]
    subnet_ids = module.vpc.private_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}

###
# Kubernetes auth
###

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.security_tools.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.security_tools.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_security_group" "security_tools_worker" {
  name   = "security-tools-worker"
  vpc_id = module.vpc.vpc_id
}

###
# AWS EKS Fargate
###

resource "aws_eks_fargate_profile" "eks_fargate" {
  cluster_name           = aws_eks_cluster.security_tools.name
  fargate_profile_name   = "security-tools-fargate-profile"
  pod_execution_role_arn = aws_iam_role.security_tools_role.arn
  subnet_ids             = ["subnet-0ac318fe8f75d5065", "subnet-0d2f5d15b09788aa9"]

  selector {
    namespace = "fargate-node"
  }
}

###
# Coredns
###

resource "aws_eks_fargate_profile" "coredns" {
  cluster_name           = aws_eks_cluster.security_tools.name
  fargate_profile_name   = "coredns"
  pod_execution_role_arn = aws_iam_role.security_tools_role.arn
  subnet_ids             = ["subnet-0ac318fe8f75d5065", "subnet-0d2f5d15b09788aa9"]
  selector {
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
    }
  }
}

data "aws_eks_cluster_auth" "security_tools" {
  name = aws_eks_cluster.security_tools.name
}

###
# AWS EKS addons
###

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.security_tools.name
  addon_name        = "coredns"
  addon_version     = var.cluster_addon_coredns_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.security_tools.name
  addon_name        = "kube-proxy"
  addon_version     = var.cluster_addon_kube_proxy_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.security_tools.name
  addon_name        = "vpc-cni"
  addon_version     = var.cluster_addon_vpc_cni_version
  resolve_conflicts = "OVERWRITE"
}
