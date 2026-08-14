# Exercise 3 - `hello-world` REST service on minikube

Deploys the provided Go `rest_1.0` app (exposing `GET /hello-world`) onto a
local minikube cluster, so a developer can run one command and immediately
hit `http://localhost:8080/hello-world` locally.

## TL;DR

```bash
cd exercise-3-k8s-rest
make deploy      # checks tooling, starts minikube, builds & deploys the app
make forward      # in a second terminal: exposes it on localhost:8080
curl http://localhost:8080/hello-world
# {"message":"Hello World"}
```

`make deploy` is fully automated end-to-end: it downloads the app archive,
starts/reuses minikube, builds the container image directly inside
minikube's own Docker daemon (**no remote registry** is used - cost/latency
saving), applies the Kubernetes manifests, waits for the rollout, and
verifies the endpoint once automatically.

## What's included

```
exercise-3-k8s-rest/
├── Dockerfile              # multi-stage build of the Go app
├── Makefile                 # check / up / deploy / forward / down / clean
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml       # imagePullPolicy: Never -> uses the local image
│   ├── service.yaml           # NodePort, used together with port-forward
│   └── kustomization.yaml
└── scripts/
    ├── check-prerequisites.sh  # verifies docker/minikube/kubectl/curl/unzip
    ├── setup-minikube.sh       # idempotent: starts or reuses a minikube profile
    ├── build-and-deploy.sh     # downloads app, builds image, deploys, verifies
    ├── forward.sh                # foreground port-forward to localhost:8080
    └── teardown.sh              # removes k8s resources (optionally the whole cluster)
```

## Step by step (what `make deploy` does)

1. **`check-prerequisites.sh`** - verifies `docker`, `minikube`, `kubectl`,
   `curl`, `unzip` are installed, with install hints if not.
2. **`setup-minikube.sh`** - starts a dedicated minikube profile
   (`hello-world-hw`, `--driver=docker`) if it isn't already running, so it
   won't interfere with any other minikube cluster you may already use.
3. **`build-and-deploy.sh`**:
   - Downloads `rest_1.0.zip` and unzips it into `app/` (git-ignored -
     fetched fresh every time, not committed).
   - Points the local `docker` CLI at **minikube's own Docker daemon**
     (`eval $(minikube docker-env)`) and builds `hello-world-rest:local`
     directly inside the cluster's runtime. This is the standard way to
     "use a local registry" for minikube without actually running one -
     the image never leaves the cluster, no push/pull, no registry cost.
   - Applies `k8s/` via Kustomize and waits for the rollout to finish.
   - Opens a temporary port-forward, curls `/hello-world` once to confirm
     it works, prints the response, and closes the port-forward again.
4. Afterwards, run **`make forward`** any time to open a long-lived
   `kubectl port-forward` on `localhost:8080`.

## Why `port-forward` instead of `minikube service`

`kubectl port-forward` behaves identically on Linux/macOS/Windows regardless
of the minikube driver, and always binds to `localhost`, matching the task's
"call a localhost URI" requirement exactly. `minikube service --url` is a
fine alternative but on the `docker` driver (macOS/Windows) it needs an extra
tunnel process - `port-forward` avoids that extra moving part.

## Cleaning up

```bash
make down     # removes the Deployment/Service/Namespace, keeps minikube running
make clean    # also deletes the minikube profile entirely
```

## Troubleshooting / if the archive layout differs

`Dockerfile` and `build-and-deploy.sh` assume the unzipped app is a standard
Go module (`go.mod` + a `main` package at the root). If `rest_1.0.zip`
actually places the source under a subfolder (e.g. `cmd/server/`):

- Adjust the `go build` line in `Dockerfile` to build that package instead
  of `.`, or
- Add a `cd`/path adjustment in `build-and-deploy.sh` right after the
  "flatten single top-level directory" step.

If the app listens on a port other than `8080`, update `containerPort` in
`k8s/deployment.yaml` (and the probes) and `targetPort`/`EXPOSE` accordingly.

## Bonus points covered

- [x] Basic documentation (this file)
- [x] Automated minikube provisioning (`scripts/setup-minikube.sh`)
- [x] Automated deployment (`scripts/build-and-deploy.sh`, `make deploy`)
- [x] Tooling checks (`scripts/check-prerequisites.sh`)
- [x] Local registry avoided - image is built straight into minikube's own
      Docker daemon instead of a remote registry
