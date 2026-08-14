# DevOps Homework

Solutions for the 3 exercises. As noted in the task description, none of
these have a single "correct" answer - each README below explains the
choices made and the trade-offs considered.

| Exercise | Folder | What it is |
|---|---|---|
| 1 - VPC module | [`exercise-1-vpc/`](exercise-1-vpc) | Terraform module: VPC, 2 public + 2 private subnets across 2 AZs, NAT for private outbound access, S3 Gateway VPC Endpoint so S3 traffic never leaves the AWS backbone. Includes a runnable example. |
| 2 - Backup bucket | [`exercise-2-backup-bucket/`](exercise-2-backup-bucket) | Terraform: S3 bucket for 180-day backup retention, Object Lock (COMPLIANCE), lifecycle expiration, encryption at rest, public access fully blocked, least-privilege cross-account bucket policy for the `backup_uploader` role. |
| 3 - minikube deployment | [`exercise-3-k8s-rest/`](exercise-3-k8s-rest) | Kubernetes manifests + automation scripts (`make deploy`) that provision minikube, build the provided Go app straight into minikube's Docker daemon (no remote registry), and deploy it so it's reachable at `http://localhost:8080/hello-world`. |

## CI

[GitHub Actions](.github/workflows) run automatically on every push/PR:

- **`terraform.yml`** - `terraform fmt -check`, `terraform init`/`validate`
  for every module and example, and (only if `AWS_ACCESS_KEY_ID` /
  `AWS_SECRET_ACCESS_KEY` repo secrets are configured) `terraform plan`.
  No `terraform apply` is ever run - nothing in this repo gets deployed,
  per the task instructions ("do not spend money").
- **`kubernetes.yml`** - `yamllint`, schema validation of the rendered
  manifests via `kubeconform`, `hadolint` on the `Dockerfile`, and
  `shellcheck` on the automation scripts.

## Repository layout

```
.
├── .github/workflows/          # CI (terraform + kubernetes)
├── exercise-1-vpc/
│   ├── modules/vpc/              # the reusable module
│   └── examples/basic/           # example that calls the module
├── exercise-2-backup-bucket/     # root module (bucket + policy)
└── exercise-3-k8s-rest/
    ├── k8s/                       # Deployment/Service/Namespace (kustomize)
    ├── scripts/                   # check/setup/build-and-deploy/forward/teardown
    ├── Dockerfile
    └── Makefile
```

## Requirements to actually run things locally

- Exercises 1 & 2: Terraform >= 1.5, AWS provider ~> 5.0 (`terraform init`,
  `validate`, `plan` all work with `-backend=false` / without AWS
  credentials; `plan` additionally needs AWS credentials since it reads
  live AZ/account data).
- Exercise 3: Docker, minikube, kubectl (see
  [`exercise-3-k8s-rest/README.md`](exercise-3-k8s-rest/README.md) -
  `scripts/check-prerequisites.sh` verifies all of this for you).
