#!/usr/bin/env bash

set -euo pipefail

echo "Checking required tools..."

required_tools=(
  docker
  kubectl
  minikube
  curl
)

for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' is not installed or not available in PATH."
    exit 1
  fi

  echo "OK: $tool"
done

echo
echo "All required tools are available."