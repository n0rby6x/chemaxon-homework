#!/usr/bin/env bash

set -euo pipefail

IMAGE="rest-service:local"
DEPLOYMENT="rest-service"
SERVICE="rest-service"

echo "==> Checking required tools"
./scripts/check-tools.sh

echo
echo "==> Starting Minikube if necessary"

if ! minikube status >/dev/null 2>&1; then
  minikube start --driver=docker
else
  echo "Minikube is already running."
fi

echo
echo "==> Building image inside Minikube"

minikube image build -t "$IMAGE" .

echo
echo "==> Deploying Kubernetes resources"

kubectl apply -f k8s/

echo
echo "==> Deploying Kubernetes resources"

kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo
echo "==> Waiting for deployment"

kubectl rollout status deployment/rest-service --timeout=120s
