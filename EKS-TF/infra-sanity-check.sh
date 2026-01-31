#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-Tetris-EKS-Cluster}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
ECR_REPO="${ECR_REPO:-react-tetris}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }
fail() { echo "❌ FAILED: $1"; exit 1; }
pass() { echo "✅ PASSED: $1"; }

log "Starting Enterprise Infrastructure Sanity Check..."

# -------------------------
# Terraform Drift Check
# -------------------------
log "Checking Terraform state drift..."
terraform plan -detailed-exitcode || fail "Terraform drift detected"
pass "Terraform state clean"

# -------------------------
# AWS EKS Cluster Check
# -------------------------
log "Checking EKS cluster availability..."
aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" > /dev/null \
  || fail "EKS cluster not reachable"
pass "EKS cluster reachable"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" > /dev/null

# -------------------------
# Kubernetes Node Health
# -------------------------
log "Checking Kubernetes nodes..."
READY_NODES=$(kubectl get nodes --no-headers | grep -c Ready || true)
[[ "$READY_NODES" -gt 0 ]] || fail "No Ready nodes"
pass "$READY_NODES nodes Ready"

# -------------------------
# System Pods Health
# -------------------------
log "Checking kube-system pods..."
FAILED_PODS=$(kubectl get pods -n kube-system --no-headers | awk '$3 != "Running" && $3 != "Completed"' | wc -l)
[[ "$FAILED_PODS" -eq 0 ]] || fail "System pods unhealthy"
pass "System pods healthy"

# -------------------------
# Metrics Server Check
# -------------------------
log "Checking metrics availability..."
kubectl top nodes > /dev/null || fail "Metrics server missing"
pass "Metrics server working"

# -------------------------
# Storage Check
# -------------------------
log "Checking storage classes..."
kubectl get storageclass > /dev/null || fail "Storage classes missing"
pass "Storage OK"

# -------------------------
# Internet Egress Test
# -------------------------
log "Testing pod internet connectivity..."
kubectl delete pod net-test --ignore-not-found > /dev/null
kubectl run net-test --image=busybox --restart=Never -- sleep 20 > /dev/null
kubectl wait --for=condition=Ready pod/net-test --timeout=30s || fail "Net test pod failed"

kubectl exec net-test -- wget -qO- https://google.com > /dev/null \
  || fail "Pod cannot access internet"
pass "Outbound internet works"

kubectl delete pod net-test > /dev/null

# -------------------------
# ECR Pull Permission Test
# -------------------------
log "Testing ECR image pull..."
ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$AWS_REGION" \
  --query 'repositories[0].repositoryUri' --output text)

kubectl delete pod ecr-test --ignore-not-found > /dev/null
kubectl run ecr-test --image="$ECR_URI:latest" --restart=Never > /dev/null

kubectl wait --for=condition=Ready pod/ecr-test --timeout=60s || fail "ECR image pull failed"
pass "ECR pull permissions OK"

kubectl delete pod ecr-test > /dev/null

# -------------------------
# LoadBalancer Provisioning Test
# -------------------------
log "Testing LoadBalancer provisioning..."
kubectl delete svc lb-test --ignore-not-found > /dev/null
kubectl create deployment lb-test --image=nginx > /dev/null
kubectl expose deployment lb-test --type=LoadBalancer --port=80 > /dev/null

sleep 10
LB_IP=$(kubectl get svc lb-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

[[ -n "$LB_IP" ]] || fail "LoadBalancer not provisioned"
pass "LoadBalancer created: $LB_IP"

kubectl delete svc lb-test > /dev/null
kubectl delete deployment lb-test > /dev/null

# -------------------------
# Final Summary
# -------------------------
log "🎉 ALL INFRASTRUCTURE CHECKS PASSED"
exit 0
