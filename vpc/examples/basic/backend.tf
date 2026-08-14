# Remote state so that the deploy/destroy GitHub Actions workflows (which
# each run on a fresh, stateless runner) share the same Terraform state
# across runs - without this, "terraform destroy" run in CI would have no
# record of what "terraform apply" created in an earlier run.
#
# Left empty on purpose (partial configuration): the actual bucket/key/
# region/lock-table values are supplied at `terraform init` time via
# `-backend-config=...` flags in the GitHub Actions workflows, so nothing
# AWS-account-specific is hardcoded into the repo.
#
# For plain local/manual use (not via CI), either pass the same
# -backend-config flags by hand, or run `terraform init -backend=false`
# to fall back to local state.
terraform {
  backend "s3" {}
}
