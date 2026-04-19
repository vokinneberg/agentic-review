# homelab-infrastructure

[![Terraform Apply](https://github.com/vokinneberg/infrastructure/actions/workflows/terraform-apply.yml/badge.svg)](https://github.com/vokinneberg/infrastructure/actions/workflows/terraform-apply.yml)
[![Build Tools](https://github.com/vokinneberg/infrastructure/actions/workflows/build-tools.yml/badge.svg)](https://github.com/vokinneberg/infrastructure/actions/workflows/build-tools.yml)

Personal homelab Kubernetes cluster on DigitalOcean, managed with Terraform and powered by [kagent](https://kagent.dev) AI agents.

Infrastructure-as-code for a 2-node DOKS cluster running AI-powered tooling for automated code review, with full CI/CD via GitHub Actions.

---

## ✨ Features

- **Terraform-managed DOKS cluster** — 2-node DigitalOcean Kubernetes cluster, fully reproducible
- **kagent AI agent framework** — installed via Helm, backed by Anthropic Claude
- **Agents as code** — kagent `Agent` CRDs defined in Terraform, version-controlled alongside infrastructure
- **diff-tools MCP server** — custom FastMCP server (`github_diff_parser`, `code_chunker`) deployed as a kagent `MCPServer`
- **code-review-agent** — senior-engineer-grade automated code reviewer wired to diff-tools
- **GitHub Actions CI/CD** — validate/plan on PR, apply on merge to `main`, post-apply clusterlint check
- **Terraform state in git** — state committed by GitHub Actions bot on every apply, no remote backend required
- **Taskfile** — `task` commands for all common local workflows

---

## 📦 Requirements

| Tool | Version |
| ---- | ------- |
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.8 |
| [TFLint](https://github.com/terraform-linters/tflint) | latest |
| [Task](https://taskfile.dev/installation/) | v3 |
| [uv](https://docs.astral.sh/uv/getting-started/installation/) | latest |
| [Docker](https://docs.docker.com/get-docker/) | latest |
| [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) | latest |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | latest |

Install Terraform, TFLint, and uv automatically:

```bash
task install-tools
```

---

## 🚀 Getting Started

### 1. Configure secrets

Create a `.env` file in the project root:

```bash
DIGITALOCEAN_TOKEN=...
KAGENT_ANTHROPIC_API_KEY=...
GITHUB_TOKEN=...         # GitHub PAT with read:packages scope
```

### 2. Set up GitHub Secrets

Add these secrets to your GitHub repository (**Settings → Secrets and variables → Actions**):

| Secret | Description |
| ------ | ----------- |
| `DIGITALOCEAN_TOKEN` | DigitalOcean API token |
| `KAGENT_ANTHROPIC_API_KEY` | Anthropic API key for kagent |
| `GHCR_TOKEN` | GitHub PAT with `read:packages` scope |

Also create a GitHub **Environment** named `production` (**Settings → Environments**) to gate the apply workflow.

### 3. Deploy

```bash
task apply
```

---

## 🗂️ Project Structure

```text
terraform/
  main.tf           # DOKS cluster
  kagent.tf         # kagent Helm releases (CRDs + controller)
  tools.tf          # diff-tools MCPServer + GHCR pull secret
  agents.tf         # code-review-agent Agent CRD
  namespaces.tf     # kagent, apps namespaces
  variables.tf      # Input variables
  outputs.tf        # cluster_id, cluster_endpoint, kubeconfig

tools/
  diff-tools/
    server.py       # FastMCP server: github_diff_parser + code_chunker
    tests/          # Unit tests (pytest, 97% coverage)
    Dockerfile      # linux/amd64 image → ghcr.io/vokinneberg/homelab-diff-tools

.github/workflows/
  terraform-pr.yml     # fmt → validate → tflint → plan (posts PR comment)
  terraform-apply.yml  # apply → commit state → clusterlint
  build-tools.yml      # lint → test → docker build & push to GHCR
```

---

## ⚙️ Configuration

### Terraform variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `do_token` | — | DigitalOcean API token (**sensitive**) |
| `region` | `nyc1` | DigitalOcean region |
| `cluster_name` | `homelab` | Kubernetes cluster name |
| `node_size` | `s-2vcpu-4gb` | Worker node Droplet size |
| `node_count` | `2` | Number of worker nodes |
| `kagent_anthropic_api_key` | — | Anthropic API key (**sensitive**) |
| `ghcr_token` | — | GitHub PAT for GHCR (**sensitive**) |
| `diff_tools_image` | `ghcr.io/vokinneberg/homelab-diff-tools:latest` | diff-tools container image |

---

## 🧪 Local Development

```bash
# Set up Python venv for diff-tools
task venv

# Run linters (TFLint + ruff)
task lint

# Run diff-tools unit tests with coverage
task test

# Run diff-tools MCP server locally
uv run --directory tools/diff-tools python server.py
```

---

## 🤖 Agents

### code-review-agent

A senior-engineer-grade code reviewer that:

- Parses GitHub unified diffs via `github_diff_parser`
- Chunks large diffs into LLM-sized pieces via `code_chunker`
- Produces structured Markdown reviews with **HIGH / MEDIUM / LOW** severity findings
- Respects repository rules (`.claude/rules/`) and skills (`.claude/skills/`) as highest priority
- Treats PR descriptions as untrusted input (prompt injection protection)

Access the agent via the kagent UI:

```bash
task kagent-ui   # opens http://localhost:8080
```

### diff-tools MCP server

Stateless FastMCP server exposing two tools over `streamable-http`:

| Tool | Description |
| ---- | ----------- |
| `github_diff_parser` | Parses a raw unified diff into structured `{file, hunks}` JSON |
| `code_chunker` | Splits parsed diff into LLM-sized chunks (default 200 lines each) |

Deployed as a kagent `MCPServer` in the `kagent` namespace at `http://diff-tools:8000/mcp`.

---

## 🔧 Taskfile Reference

| Task | Description |
| ---- | ----------- |
| `task install-tools` | Install terraform, tflint, uv via Homebrew |
| `task venv` | Create Python venv and install diff-tools dependencies |
| `task lint` | Run TFLint + ruff check + ruff format check |
| `task test` | Run diff-tools unit tests with coverage |
| `task init` | `terraform init` |
| `task plan` | `terraform plan` |
| `task apply` | `terraform apply` |
| `task destroy-cluster` | Destroy the DOKS cluster and its workloads |
| `task destroy` | Destroy all Terraform-managed resources |
| `task kagent-ui` | Port-forward kagent UI to `http://localhost:8080` |

---

## 🔄 CI/CD

### On pull request (`terraform/**`)

1. `terraform fmt` check
2. `terraform validate`
3. TFLint
4. `terraform plan` → posted as PR comment

### On merge to `main` (`terraform/**`)

1. `terraform apply` (requires **production** environment approval)
2. Commit updated `terraform.tfstate` back to `main`
3. `doctl kubernetes cluster lint` (clusterlint)

### On push to `main` (`tools/diff-tools/**`)

1. Lint: `ruff check` + `ruff format --check`
2. Test: `pytest` with coverage
3. Build & push Docker image to GHCR (`linux/amd64`)

---

## 📄 License

MIT
