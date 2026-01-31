resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.EKSClusterRole.arn
  vpc_config {
    subnet_ids         = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id, aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  version = "1.33"

  depends_on = [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy]
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks-cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks-cluster.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
