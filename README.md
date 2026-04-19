# Homelab Infrastructure

Terraform-managed Kubernetes homelab on DigitalOcean, running [kagent](https://kagent.dev) and [OpenClaw](https://myclaw.ai).

## Cluster

| Property | Value |
| --- | --- |
| Provider | DigitalOcean Kubernetes (DOKS) |
| Region | Frankfurt (`fra1`) |
| Nodes | 2 × `s-2vcpu-4gb` |
| Kubernetes | 1.32.x (latest patch, auto-selected) |

## Namespaces

| Namespace | Purpose |
| --- | --- |
| `kagent` | kagent AI agent framework |
| `openclaw` | OpenClaw personal AI assistant |
| `experimental` | Personal experiments |

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.8
2. [TFLint](https://github.com/terraform-linters/tflint) >= 0.53
3. A DigitalOcean account with:
   - An API token
   - A **Spaces** bucket named `homelab-tf-state` in `fra1` (for Terraform state)
   - Spaces access key + secret

## GitHub Secrets

Configure these in your repository's **Settings → Secrets and variables → Actions**:

| Secret | Description |
| --- | --- |
| `DIGITALOCEAN_TOKEN` | DigitalOcean API token |
| `SPACES_ACCESS_KEY_ID` | DO Spaces access key (for Terraform state backend) |
| `SPACES_SECRET_ACCESS_KEY` | DO Spaces secret key |
| `KAGENT_ANTHROPIC_API_KEY` | Anthropic API key passed to kagent |

Also create a GitHub **Environment** named `production` (Settings → Environments) and add the same secrets there to gate the apply workflow.

## Local Usage

```bash
cd terraform

export AWS_ACCESS_KEY_ID=<spaces-access-key>
export AWS_SECRET_ACCESS_KEY=<spaces-secret-key>

terraform init

terraform plan \
  -var="do_token=<your-do-token>" \
  -var="kagent_anthropic_api_key=<your-anthropic-key>"

terraform apply \
  -var="do_token=<your-do-token>" \
  -var="kagent_anthropic_api_key=<your-anthropic-key>"
```

## CI/CD

| Trigger | Workflow | Steps |
| --- | --- | --- |
| Pull request to `main` | `terraform-pr.yml` | fmt check → validate → TFLint → plan (posted as PR comment) |
| Merge to `main` | `terraform-apply.yml` | init → apply (requires `production` environment approval) |

## Customising

All tuneable values are in [terraform/variables.tf](terraform/variables.tf). Override them with `-var` flags or a `terraform.tfvars` file (gitignored).
