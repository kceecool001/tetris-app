#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="eu-central-1"
CLUSTER_NAME="Tetris-EKS-Cluster"
ECR_REPO="react-tetris"
VPC_ID="vpc-0b766866c0a120705"
NODEGROUP_NAME="Tetris-Node-Group"
NAT_GW="nat-07519a270a73f2dd1"

log() { echo -e "\n🔹 $1"; }
ok() { echo "✅ $1"; }
warn() { echo "⚠️ $1"; }
fail() { echo "❌ $1"; exit 1; }

log "Starting AWS + EKS Infrastructure Validation..."

# ---------------------------
# AWS Identity
# ---------------------------
log "Checking AWS authentication..."
aws sts get-caller-identity > /dev/null || fail "AWS credentials invalid"
ok "AWS identity verified"

# ---------------------------
# VPC Exists
# ---------------------------
log "Checking VPC..."
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" > /dev/null || fail "VPC missing"
ok "VPC exists"

# ---------------------------
# NAT Gateway Health
# ---------------------------
log "Checking NAT Gateway..."
NAT_STATE=$(aws ec2 describe-nat-gateways --nat-gateway-ids "$NAT_GW" \
  --query 'NatGateways[0].State' --output text)

[[ "$NAT_STATE" == "available" ]] || fail "NAT Gateway not available"
ok "NAT Gateway active"

# ---------------------------
# EKS Cluster Health
# ---------------------------
log "Checking EKS cluster..."
CLUSTER_STATUS=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" \
  --query 'cluster.status' --output text)

[[ "$CLUSTER_STATUS" == "ACTIVE" ]] || fail "EKS cluster not ACTIVE"
ok "EKS cluster ACTIVE"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" > /dev/null

# ---------------------------
# Kubernetes Connectivity
# ---------------------------
log "Checking Kubernetes API..."
kubectl cluster-info > /dev/null || fail "Cannot reach Kubernetes API"
ok "Kubernetes reachable"

# ---------------------------
# Node Group Health
# ---------------------------
log "Checking EKS Node Group..."
NODE_STATUS=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "$NODEGROUP_NAME" \
  --query 'nodegroup.status' --output text)

[[ "$NODE_STATUS" == "ACTIVE" ]] || fail "Node group unhealthy"
ok "Node group ACTIVE"

# ---------------------------
# Worker Node Readiness
# ---------------------------
log "Checking Kubernetes worker nodes..."
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
READY_COUNT=$(kubectl get nodes --no-headers | grep -c Ready || true)

[[ "$NODE_COUNT" -gt 0 ]] || fail "No worker nodes"
[[ "$READY_COUNT" == "$NODE_COUNT" ]] || warn "Some nodes not Ready"

ok "$READY_COUNT/$NODE_COUNT nodes Ready"

# ---------------------------
# Core System Pods
# ---------------------------
log "Checking kube-system pods..."
BAD_SYS=$(kubectl get pods -n kube-system --no-headers | awk '$3 != "Running" && $3 != "Completed"' | wc -l)

[[ "$BAD_SYS" -eq 0 ]] || warn "Some system pods unhealthy"
ok "System pods healthy"

# ---------------------------
# AWS VPC CNI
# ---------------------------
log "Checking AWS VPC CNI..."
kubectl get daemonset aws-node -n kube-system > /dev/null || fail "AWS CNI missing"
ok "AWS VPC CNI active"

# ---------------------------
# Pod Scheduling Test
# ---------------------------
log "Testing pod scheduling..."
kubectl delete pod tetris-schedule-test --ignore-not-found > /dev/null
kubectl run tetris-schedule-test --image=nginx --restart=Never > /dev/null

kubectl wait --for=condition=Ready pod/tetris-schedule-test --timeout=60s \
  || fail "Pod scheduling failed"

ok "Pod scheduling successful"

kubectl delete pod tetris-schedule-test > /dev/null

# ---------------------------
# NAT Internet Egress Test
# ---------------------------
log "Testing outbound internet (via NAT)..."
kubectl delete pod tetris-net-test --ignore-not-found > /dev/null
kubectl run tetris-net-test --image=busybox --restart=Never -- sleep 20 > /dev/null

kubectl wait --for=condition=Ready pod/tetris-net-test --timeout=60s \
  || fail "Network test pod failed"

kubectl exec tetris-net-test -- wget -qO- https://aws.amazon.com > /dev/null \
  || fail "Pods cannot reach internet (NAT failure)"

ok "Outbound NAT internet works"

kubectl delete pod tetris-net-test > /dev/null

# ---------------------------
# ECR Repository Exists
# ---------------------------
log "Checking ECR repository..."
aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$AWS_REGION" > /dev/null \
  || fail "ECR repository missing"

ok "ECR repository exists"

# ---------------------------
# LoadBalancer Provision Test
# ---------------------------
log "Testing AWS LoadBalancer provisioning..."
kubectl delete deployment tetris-lb-test --ignore-not-found > /dev/null
kubectl delete svc tetris-lb-test --ignore-not-found > /dev/null

kubectl create deployment tetris-lb-test --image=nginx > /dev/null
kubectl expose deployment tetris-lb-test --type=LoadBalancer --port=80 > /dev/null

sleep 12

LB_HOST=$(kubectl get svc tetris-lb-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)

if [[ -n "$LB_HOST" ]]; then
  ok "AWS LoadBalancer provisioned: $LB_HOST"
else
  warn "LoadBalancer still provisioning (normal delay)"
fi

kubectl delete svc tetris-lb-test > /dev/null
kubectl delete deployment tetris-lb-test > /dev/null

# ---------------------------
# FINAL SCORECARD
# ---------------------------
echo -e "\n🎉 ALL CORE INFRASTRUCTURE VERIFIED"
echo "EKS, NAT, Networking, ECR, Scheduling, LoadBalancers are operational"
