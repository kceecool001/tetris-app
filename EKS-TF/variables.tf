variable "vpc-name" {}
variable "igw-name" {}
variable "rt-name2" {}
variable "subnet-name" {}
variable "subnet-name2" {}
variable "security-group-name" {}
variable "iam-role-eks" {}
variable "iam-role-node" {}
variable "iam-policy-eks" {}
variable "iam-policy-node" {}
variable "cluster_name" {}
variable "eksnode-group-name" {}

variable "region" {
  default = "eu-central-1"
}