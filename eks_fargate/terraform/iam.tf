###
# AWS EKS IAM cluster roles
###

resource "aws_iam_role" "security_tools_role" {
  name               = "SecurityCluster"
  assume_role_policy = data.aws_iam_policy_document.eks_service_assume.json
}

data "aws_iam_policy_document" "eks_service_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.security_tools_role.name
}

# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.security_tools_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.security_tools_role.name
}

###
# AWS EKS IAM worker role
###

resource "aws_iam_role" "security_tools_worker_role" {
  name               = "SecurityClusterWorker"
  assume_role_policy = data.aws_iam_policy_document.ec2_service_assume.json
}

data "aws_iam_policy_document" "ec2_service_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks-worker-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.security_tools_worker_role.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.security_tools_worker_role.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.security_tools_worker_role.name
}

resource "aws_iam_role_policy_attachment" "eks-worker-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.security_tools_worker_role.name
}

###
# AWS EKS Service account
###

data "tls_certificate" "security_tools" {
  url = aws_eks_cluster.security_tools.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "security_tools" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.security_tools.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.security_tools.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "security_tools_service_account" {
  name               = "SecurityClusterServiceAccount"
  assume_role_policy = data.aws_iam_policy_document.security_tools_service_account_assume.json
}

data "aws_iam_policy_document" "security_tools_service_account_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.security_tools.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:development:s3-read"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.security_tools.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.security_tools_service_account.name
  policy_arn = aws_iam_policy.s3_read.arn
}

resource "aws_iam_policy" "s3_read" {
  name   = "ReadAllThemBuckets"
  path   = "/"
  policy = data.aws_iam_policy_document.s3_read.json
}

data "aws_iam_policy_document" "s3_read" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = ["*"]
  }
}
