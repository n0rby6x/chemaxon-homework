# vpc

Terraform module that deploys a VPC with internet access, 4 subnets across
2 AZs (2 public + 2 private), and an S3 Gateway VPC Endpoint - plus GitHub
Actions to plan automatically and deploy/destroy on demand.

## Structure

```
.
├── .github/workflows/
│   ├── terraform.yml   # fmt + validate + plan -> auto on push to `dev` / PRs
│   ├── deploy.yml       # terraform apply -> manual, confirmation required
│   └── destroy.yml      # terraform destroy -> manual, confirmation required
├── modules/
│   └── vpc/               # the reusable module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── examples/
    └── basic/              # example root module that calls modules/vpc
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── backend.tf       # S3 remote state (partial config, filled in by CI)
        └── versions.tf
```

## What gets created

- 1 **VPC** with DNS support/hostnames enabled
- 1 **Internet Gateway**
- **2 public subnets** (1 per AZ) - `map_public_ip_on_launch = true`, routed
  straight to the Internet Gateway. Intended for a load balancer/reverse
  proxy - can talk to the internet directly.
- **2 private subnets** (1 per AZ) - no direct route to the Internet
  Gateway. Intended for application servers - outbound-only internet access
  via NAT Gateway.
- **NAT Gateway(s)** for the private subnets' outbound access.
- An **S3 Gateway VPC Endpoint**, attached to every route table.

## Answers to the review questions

**Which CIDR blocks are used?**
VPC: `10.0.0.0/16`. Public subnets: `10.0.0.0/24`, `10.0.1.0/24`. Private
subnets: `10.0.10.0/24`, `10.0.11.0/24`. Public and private ranges are kept
in clearly separate blocks (`.0-.1` vs `.10-.11`) purely for readability -
all are `/24` (254 usable IPs each), which is comfortably sized for a LB
tier and an app tier without wasting the whole `/16`. All 4 are inside the
VPC's `/16`, non-overlapping, and everything is configurable via variables
if a real deployment needs different sizing.

**How is the S3 VPC endpoint configured?**
As a **Gateway** endpoint (`aws_vpc_endpoint`, `vpc_endpoint_type = "Gateway"`),
not an Interface/PrivateLink endpoint. Gateway endpoints are free and are
exactly what AWS recommends for S3 (and DynamoDB): they work by adding a
route via an AWS-managed prefix list to the route tables you attach them
to, so traffic to S3 goes straight over the AWS backbone instead of out
through the IGW/NAT. It's attached to **both** the public and all private
route tables, so every subnet benefits - for the private subnets this also
avoids NAT Gateway per-GB data-processing charges on S3 traffic.

**What type of NAT is used (instead of the IGW)?**
The AWS-managed **NAT Gateway** resource (`aws_nat_gateway`), not a
self-managed NAT instance on EC2. It's fully managed (no OS/patching, no
scaling to think about), highly available within its AZ, and scales
automatically. A NAT instance would be cheaper at very low/near-zero
traffic, but shifts real operational burden onto you (own the AMI, patch
it, and build your own HA/failover). `single_nat_gateway` (default `true`)
lets you pick 1 shared NAT Gateway (cheaper, one AZ is a SPOF for outbound
traffic) or 1 per AZ (`false`, fully HA, ~2x NAT Gateway cost).

## Local usage

```bash
cd examples/basic
terraform init          # local state (no backend config needed locally)
terraform validate
terraform plan
```

No `terraform apply` is required to satisfy the exercise - the module and
example only need to `plan` cleanly. Applying it (see below) is optional,
for testing against your own AWS account.

---

## GitHub Actions

### 1. `terraform.yml` - automatic, plan-only

Runs on every push to the `dev` branch and on every PR that touches
`modules/**` or `examples/**`: `terraform fmt -check`, `terraform validate`
for both `modules/vpc` and `examples/basic`, and `terraform plan` for
`examples/basic`. **Never runs `apply`.**

### 2. `deploy.yml` - manual, `terraform apply`

Only runs when triggered by hand (Actions tab -> "Deploy to AWS" -> "Run
workflow"), and only if you type `deploy` into the confirmation input.
Also gated behind the `aws-production` GitHub Environment (see setup below)
so you can require manual approval before it's allowed to run at all.

### 3. `destroy.yml` - manual, `terraform destroy`

Same pattern as `deploy.yml`, but tears down what was created - type
`destroy` to confirm. **Run this after testing** so the NAT Gateway/EIP
don't keep accruing cost.

---

## One-time AWS setup (needed for `deploy.yml` / `destroy.yml` to work)

`deploy`/`destroy` run on fresh GitHub-hosted runners with no local state,
so they need **remote state in S3** to know what was created by a previous
run. This has to be created once, by hand, before the workflows are used -
Terraform can't manage its own state bucket (chicken-and-egg problem).

### Step 1 - create the state bucket + lock table

In the AWS Console (or CLI), in your test account:

1. **S3 bucket** for state, e.g. `<yourname>-vpc-tfstate` (bucket names are
   globally unique, pick something specific to you).
   - Enable **Bucket Versioning** (lets you recover a previous state file).
   - Enable **default encryption** (SSE-S3 is fine).
   - Block all public access (default when you create a bucket today).
2. **DynamoDB table** for state locking (prevents two workflow runs from
   applying at the same time), e.g. `vpc-tfstate-lock`:
   - Partition key: `LockID` (type: String) - exact name required by the
     Terraform S3 backend.
   - On-demand (pay-per-request) capacity mode is enough; the table will
     see almost no traffic.

### Step 2 - IAM permissions

The AWS credentials used by GitHub Actions need write access this time
(not just `ReadOnlyAccess` like the plan-only setup you tested earlier),
because `deploy.yml` actually creates resources, and both workflows read/
write the state bucket and lock table. Attach a policy like this to the
IAM user (or role, see OIDC note below):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VpcResources",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:ModifyVpcEndpoint",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformStateBucket",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::<yourname>-vpc-tfstate/vpc/*"
    },
    {
      "Sid": "TerraformStateBucketList",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::<yourname>-vpc-tfstate"
    },
    {
      "Sid": "TerraformStateLock",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/vpc-tfstate-lock"
    }
  ]
}
```

(Replace `<yourname>-vpc-tfstate` and the DynamoDB table ARN with your real
names/account/region.) Simplest alternative for a throwaway test account:
attach the AWS-managed `AmazonVPCFullAccess` policy plus the two
state/lock statements above - less precise, but fine for testing.

You can reuse the **same** IAM user/access key you already created for the
plan-only setup - just widen its permissions (or create a second, separate
user specifically for `deploy`/`destroy` if you'd rather keep the
plan-only credentials strictly read-only).

### Step 3 - GitHub repo configuration

**Settings -> Secrets and variables -> Actions -> Secrets** (unchanged from
before):
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Settings -> Secrets and variables -> Actions -> Variables** (add 2 new
ones on top of `AWS_REGION`):
- `AWS_REGION` - e.g. `eu-central-1`
- `TF_STATE_BUCKET` - the bucket name from Step 1, e.g. `<yourname>-vpc-tfstate`
- `TF_STATE_LOCK_TABLE` - the DynamoDB table name from Step 1, e.g. `vpc-tfstate-lock`

**Settings -> Environments -> New environment**, name it `aws-production`
(this name is referenced by `deploy.yml`/`destroy.yml`). Optionally enable
**Required reviewers** so someone has to click "approve" before an `apply`
or `destroy` run is allowed to actually execute - recommended even for a
test account, so nothing runs by an accidental click.

### Cost note

NAT Gateway (~$0.045-0.059/hr depending on region, plus per-GB data
processing) and the associated Elastic IP are **not** part of the AWS free
tier. Everything else this module creates (VPC, subnets, IGW, route
tables, S3 Gateway endpoint) is free. Run `destroy.yml` when you're done
testing so the NAT Gateway doesn't keep billing.
