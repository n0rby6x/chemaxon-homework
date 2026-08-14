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
echo "==> Waiting for deployment"

kubectl rollout status deployment/"$DEPLOYMENT" --timeout=120s

echo
echo "==> Deployment successful"

kubectl get pods
kubectl get service "$SERVICE"

echo
echo "The application is deployed."
echo
echo "Run the following command in another terminal:"
echo
echo "  kubectl port-forward service/$SERVICE 8080:8080"
echo
echo "Then test:"
echo
echo "  curl http://localhost:8080/hello-world"