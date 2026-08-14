#!/usr/bin/env bash
# Checks that everything needed to build & run this exercise is installed.
# Cross-platform (Linux/macOS/WSL) - only requires common CLI tools.

set -uo pipefail

missing=0

check() {
  local name="$1"
  local hint="$2"
  if command -v "$name" >/dev/null 2>&1; then
    echo "[OK]      $name found: $($name --version 2>&1 | head -n1)"
  else
    echo "[MISSING] $name not found. $hint"
    missing=1
  fi
}

echo "Checking required tooling..."
echo "-----------------------------"

check docker    "Install from https://docs.docker.com/get-docker/"
check minikube  "Install from https://minikube.sigs.k8s.io/docs/start/"
check kubectl   "Install from https://kubernetes.io/docs/tasks/tools/"
check curl      "Install via your OS package manager (apt/brew/dnf/...)"
check unzip     "Install via your OS package manager (apt/brew/dnf/...)"

echo "-----------------------------"

if [ "$missing" -ne 0 ]; then
  echo "One or more required tools are missing - install them and re-run this script."
  exit 1
fi

echo "All prerequisites are present."
