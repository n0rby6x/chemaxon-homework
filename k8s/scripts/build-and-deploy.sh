#!/usr/bin/env bash
# Downloads the rest_1.0 Go app, builds it into minikube's own Docker
# daemon (no remote registry needed/used), and deploys it to the
# "hello-world" namespace on minikube.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${MINIKUBE_PROFILE:-hello-world-hw}"
APP_ZIP_URL="${APP_ZIP_URL:-https://github.com/DawiX/rest-hw-dwnld/raw/refs/heads/main/rest_1.0.zip}"
APP_DIR="$HERE/app"
IMAGE_NAME="hello-world-rest:local"

echo "==> 1/5 Checking prerequisites"
"$HERE/scripts/check-prerequisites.sh"

echo "==> 2/5 Making sure minikube is running"
"$HERE/scripts/setup-minikube.sh"

echo "==> 3/5 Fetching application source"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
TMP_ZIP="$(mktemp -t rest_app_XXXX.zip)"
curl -fsSL "$APP_ZIP_URL" -o "$TMP_ZIP"
unzip -q "$TMP_ZIP" -d "$APP_DIR"
rm -f "$TMP_ZIP"

# If the zip contained a single top-level directory, flatten it so go.mod
# ends up directly under app/ (adjust here if the real archive layout
# differs - see README "Troubleshooting").
entries=("$APP_DIR"/*)
if [ "${#entries[@]}" -eq 1 ] && [ -d "${entries[0]}" ]; then
  inner="${entries[0]}"
  shopt -s dotglob
  mv "$inner"/* "$APP_DIR"/
  shopt -u dotglob
  rmdir "$inner"
fi

echo "==> 4/5 Building the container image inside minikube's Docker daemon"
eval "$(minikube -p "$PROFILE" docker-env)"
docker build -t "$IMAGE_NAME" "$HERE"

echo "==> 5/5 Deploying to minikube"
kubectl apply -k "$HERE/k8s"
kubectl rollout status deployment/hello-world-rest -n hello-world --timeout=120s

echo ""
echo "Deployment complete. Verifying the endpoint..."
kubectl -n hello-world port-forward svc/hello-world-rest 8080:80 >/tmp/hello-world-rest-portforward.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID >/dev/null 2>&1 || true' EXIT

# Give the port-forward a moment to come up.
for _ in $(seq 1 10); do
  if curl -fsS "http://localhost:8080/hello-world" >/tmp/hello-world-rest-response.json 2>/dev/null; then
    break
  fi
  sleep 1
done

if [ -s /tmp/hello-world-rest-response.json ]; then
  echo "Response from http://localhost:8080/hello-world :"
  cat /tmp/hello-world-rest-response.json
  echo ""
else
  echo "Could not verify the endpoint automatically - check /tmp/hello-world-rest-portforward.log"
fi

kill "$PF_PID" >/dev/null 2>&1 || true
trap - EXIT

echo ""
echo "To reach the service anytime, run:"
echo "  make forward"
echo "and then open http://localhost:8080/hello-world"
