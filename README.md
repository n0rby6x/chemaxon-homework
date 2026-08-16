# chemaxon-homework

Solutions for the 3 exercises. As noted in the task description, none of
these have a single "correct" answer - the choices made and trade-offs
considered are documented inline in the Terraform/Kubernetes files.

## Layout

```
.
├── .github/workflows/
│   ├── terraform.yml      # fmt + validate + plan, on push to `dev`
│   └── k8s.yml              # full build -> deploy -> test cycle on minikube, in CI
├── terraform/
│   ├── vpc/
│   │   ├── modules/vpc/          # Exercise 1: reusable VPC module
│   │   └── examples/basic/       # example that calls the module (+ S3 remote state backend.tf)
│   └── backup-bucket/             # Exercise 2: S3 backup bucket (flat root module)
├── k8s/                            # Exercise 3: Kubernetes manifests + automation
│   ├── namespace.yaml, deployment.yaml, service.yaml, kustomization.yaml
│   ├── Makefile                    # check / minikube / build / deploy / test / stop / clean
│   └── scripts/                    # check-prerequisites, deploy, forward, setup-minikube, teardown, test
├── Dockerfile                       # packages the prebuilt Go binary below
└── rest_1.0_linux_amd64              # prebuilt static binary of the provided REST app
```

## Exercise 1 - VPC (`terraform/vpc/`)

A Terraform module deploying a VPC with internet access: 2 public subnets
(routed to an Internet Gateway - for a load balancer/reverse proxy) and 2
private subnets (routed via NAT Gateway for outbound-only access - for
application servers), across 2 AZs, plus an S3 Gateway VPC Endpoint so S3
API calls from inside the VPC never leave the AWS backbone network.
`examples/basic/` shows the module in use and is the target of CI `plan`.

## Exercise 2 - Backup bucket (`terraform/backup-bucket/`)

An S3 bucket for storing filesystem backups for exactly 180 days: Object
Lock (COMPLIANCE mode) so backups can't be deleted/overwritten early,
lifecycle expiration so they're deleted once the retention window is up,
versioning, encryption at rest (SSE-S3 by default, optional customer-managed
KMS key), public access fully blocked, and a least-privilege bucket policy
granting the cross-account `backup_uploader` role exactly the permissions
it needs to upload.

## Exercise 3 - REST service on minikube (`k8s/`)

Deploys the provided `rest_1.0` Go binary (committed directly as
`rest_1.0_linux_amd64`, packaged by the root `Dockerfile`) onto a local
minikube cluster.

```bash
cd k8s
make check     # verifies docker/kubectl/minikube/curl are installed
make minikube   # starts minikube (--driver=docker)
make build       # builds the image straight into minikube (no remote registry)
make deploy       # applies the manifests and waits for the rollout
make test          # curls the endpoint and checks the response
```

Once deployed, port-forward the service and call it locally:

```bash
kubectl port-forward service/rest-service 8080:8080
curl http://localhost:8080/hello-world
```

## CI

[GitHub Actions](.github/workflows) run automatically:

- **`terraform.yml`** (push to `dev`, or manual) - `terraform fmt -check`,
  `terraform init`/`validate` for every module (`terraform/vpc/modules/vpc`,
  `terraform/vpc/examples/basic`, `terraform/backup-bucket`), and
  `terraform plan` (using the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
  repo secrets and the `AWS_REGION` / `TF_STATE_BUCKET` repo variables).
  No `terraform apply` runs here - nothing gets deployed by this workflow.
- **`k8s.yml`** (every push/PR) - the most thorough check in this repo: it
  actually starts a minikube cluster on the runner, builds the Docker
  image, loads it into minikube, deploys the manifests, waits for the
  rollout, port-forwards, and curls `/hello-world` to confirm the real
  response before tearing the cluster down. This is a genuine end-to-end
  test, not just linting.

## Requirements to run things locally

- **Terraform exercises**: Terraform >= 1.5, AWS provider >= 5.0.
  `terraform init -backend=false`, `validate`, and `plan` all work without
  AWS credentials for `-backend=false`; a real `plan` against AWS needs
  credentials since it reads live account/AZ data.
- **Kubernetes exercise**: Docker, minikube, kubectl (see `k8s/scripts/check-prerequisites.sh`,
  or just run `make check`).
