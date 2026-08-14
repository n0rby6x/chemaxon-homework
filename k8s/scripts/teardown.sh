#!/usr/bin/env bash
# Removes the deployed resources and, optionally, the whole minikube profile.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${MINIKUBE_PROFILE:-hello-world-hw}"

echo "Deleting Kubernetes resources..."
kubectl delete -k "$HERE/k8s" --ignore-not-found=true

if [ "${1:-}" = "--full" ]; then
  echo "Deleting minikube profile '$PROFILE'..."
  minikube delete -p "$PROFILE"
else
  echo "Kubernetes resources removed. minikube profile '$PROFILE' left running."
  echo "Run '$0 --full' to also delete the minikube profile."
fi
