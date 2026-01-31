############################################
# VPC OUTPUTS
############################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

############################################
# SUBNET OUTPUTS
############################################

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    aws_subnet.public_subnet1.id,
    aws_subnet.public_subnet2.id
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id
  ]
}

############################################
# ROUTE TABLE OUTPUTS
############################################

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private_rt.id
}

############################################
# INTERNET GATEWAY & NAT OUTPUTS
############################################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.nat_gw.id
}

output "nat_eip" {
  description = "Elastic IP associated with the NAT Gateway"
  value       = aws_eip.nat_eip.public_ip
}

############################################
# SECURITY GROUP OUTPUTS
############################################

output "eks_cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

############################################
# EKS CLUSTER OUTPUTS
############################################

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks-cluster.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.eks-cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  description = "Certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.eks-cluster.certificate_authority[0].data
}

############################################
# NODE GROUP OUTPUTS
############################################

output "eks_node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.eks-node-group.node_group_name
}

output "eks_node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.eks-node-group.arn
}
output "ecr_repo_url" {
  value = aws_ecr_repository.react_tetris.repository_url
}
