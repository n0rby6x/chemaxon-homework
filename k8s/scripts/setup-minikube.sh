#!/usr/bin/env bash
# Provisions (or reuses) a local minikube cluster for this exercise.

set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-hello-world-hw}"

if minikube status -p "$PROFILE" >/dev/null 2>&1; then
  echo "minikube profile '$PROFILE' is already running, reusing it."
else
  echo "Starting minikube profile '$PROFILE' (driver: docker)..."
  minikube start -p "$PROFILE" --driver=docker --cpus=2 --memory=2200mb
fi

kubectl config use-context "$PROFILE"

echo "minikube is ready. Current context: $(kubectl config current-context)"
