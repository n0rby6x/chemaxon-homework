#!/usr/bin/env bash
# Opens a foreground port-forward so the service is reachable at
# http://localhost:8080/hello-world . Ctrl+C to stop.

set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-hello-world-hw}"
kubectl config use-context "$PROFILE" >/dev/null

echo "Forwarding http://localhost:8080 -> service/hello-world-rest (namespace: hello-world)"
echo "Try: curl http://localhost:8080/hello-world"
kubectl -n hello-world port-forward svc/hello-world-rest 8080:80
