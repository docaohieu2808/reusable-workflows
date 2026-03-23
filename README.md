# GitHub Actions Reusable Workflows — Zero-Config Auto Pipeline

A composite GitHub Action that auto-detects language, builds, tests, and deploys any project. Works as a reusable workflow called from any repo with 2 lines, or as a composite action embedded directly in a workflow.

## How it works

```
caller repo: uses: docaohieu2808/reusable-workflows/.github/workflows/auto-pipeline.yml@master
                        ↓
              actions/detect   — inspect repo files → output language
                        ↓
              actions/build    — language-specific build
                        ↓
              actions/test     — unit tests + lint (parallel)
                        ↓
              docker login → build → push (if docker_build_enabled=true)
                        ↓
              actions/deploy   — deploy to target (if deploy_target set)
```

Config priority: action defaults → caller `with:` inputs → `.ci.yml` in project root (read by detect action).

---

## Levels

| Level | What you get |
|-------|-------------|
| **L1** | 2-line workflow. Auto-detect language, build, test, lint. No config needed. |
| **L2** | Pass `with:` inputs inline — set deploy target, docker registry, skip flags. |
| **L3** | Add `.ci.yml` to project root for per-project config without touching the workflow file. |
| **L4** | Use individual composite actions (`actions/detect`, `actions/build`, etc.) to compose custom workflows. |
| **MAX** | Self-host runners via ARC (Actions Runner Controller) on K8s — see `arc/` directory. |

---

## Prerequisites

- GitHub repository (public or private)
- For Docker builds: no extra setup — uses `docker` available on `ubuntu-latest`
- For SSH deploy targets: `DEPLOY_KEY` secret set in repo/org settings
- For AWS targets: `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` secrets
- For ARC self-hosted runners: K3s/K8s cluster + Helm

---

## Quick Start

### Zero config (L1)

Create `.github/workflows/ci.yml` in your repo:

```yaml
name: CI/CD
on: [push, pull_request]
jobs:
  pipeline:
    uses: docaohieu2808/reusable-workflows/.github/workflows/auto-pipeline.yml@master
    secrets: inherit
```

Language is auto-detected. Build, test, and lint run automatically.

### With deploy (L2)

```yaml
name: CI/CD with Overrides
on:
  push:
    branches: [main, master, staging]
  pull_request:

jobs:
  pipeline:
    uses: docaohieu2808/reusable-workflows/.github/workflows/auto-pipeline.yml@master
    secrets: inherit
    with:
      deploy_target: docker-compose
      deploy_host: app.example.com
      deploy_user: ubuntu
      deploy_path: /opt/myapp
      deploy_port: "22"
      docker_registry: ghcr.io
      docker_image: ghcr.io/myorg/myapp
      node_version: "20"
```

Add `DEPLOY_KEY` as a repository secret (SSH private key with deploy access).

### With Docker + SSH build (full example)

```yaml
jobs:
  pipeline:
    uses: docaohieu2808/reusable-workflows/.github/workflows/auto-pipeline.yml@master
    secrets: inherit
    with:
      docker_build_enabled: true
      docker_image: ghcr.io/myorg/myapp
      docker_registry: ghcr.io
      docker_registry_username: ${{ github.actor }}
      deploy_target: ssh-build
      deploy_host: 10.0.0.10
      deploy_user: deploy
      deploy_path: /opt/myapp
```

---

## Inputs Reference

### Language / Runtime

| Input | Default | Description |
|-------|---------|-------------|
| `language` | auto | Force language: `node\|java\|go\|python\|php\|rust\|dotnet` |
| `node_version` | auto | Node.js version (e.g. `"20"`) |
| `java_version` | `"21"` | Java version |
| `go_version` | auto | Go version |
| `python_version` | `"3.12"` | Python version |

### Test

| Input | Default | Description |
|-------|---------|-------------|
| `skip_tests` | `false` | Skip unit tests (lint still runs) |
| `skip_lint` | `false` | Skip lint entirely |

### Docker

| Input | Default | Description |
|-------|---------|-------------|
| `docker_build_enabled` | `false` | Build and push Docker image after tests |
| `docker_image` | `""` | Image name, e.g. `ghcr.io/org/app` |
| `docker_tag` | `github.sha[:7]` | Image tag |
| `dockerfile_path` | `Dockerfile` | Path to Dockerfile |
| `docker_registry` | `ghcr.io` | Registry host |
| `docker_registry_username` | `""` | Registry username (pass via secrets) |
| `docker_registry_password` | `""` | Registry password/token |

### Deploy

| Input | Default | Description |
|-------|---------|-------------|
| `deploy_target` | `""` | `ssh-build\|docker-compose\|s3-cloudfront\|rsync\|k8s\|helm\|vercel\|netlify\|fly-io\|railway` |
| `deploy_host` | `""` | SSH hostname/IP |
| `deploy_user` | `deploy` | SSH user |
| `deploy_path` | `/opt/app` | Remote deploy directory |
| `deploy_port` | `22` | SSH port |

### Outputs

| Output | Description |
|--------|-------------|
| `language` | Auto-detected (or forced) language |
| `has_dockerfile` | Whether Dockerfile was found |
| `docker_image_tag` | Full `image:tag` that was built and pushed |

---

## ARC Self-Hosted Runners

For private infrastructure or cost savings, run GitHub Actions on your own K8s cluster using [Actions Runner Controller](https://github.com/actions/actions-runner-controller).

```bash
# Install ARC (one-time, on K3s)
helm install arc \
  --namespace arc-systems \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

# Deploy runner scale set (see arc/arc-runner-scale-set-helm-values-docaohieu2808.yaml)
helm install arc-runner-set \
  --namespace arc-runners \
  --create-namespace \
  -f arc/arc-runner-scale-set-helm-values-docaohieu2808.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

Then target your self-hosted runners in workflows:

```yaml
jobs:
  pipeline:
    runs-on: arc-runner-set   # matches runnerScaleSetName in helm values
    uses: docaohieu2808/reusable-workflows/.github/workflows/auto-pipeline.yml@master
    secrets: inherit
```

---

## Repository Structure

```
reusable-workflows/
├── action.yml                          # Composite action entry point
├── actions/
│   ├── detect/action.yml               # Language + framework detection
│   ├── build/action.yml                # Language-specific build
│   ├── test/action.yml                 # Tests + lint
│   └── deploy/action.yml               # Deploy to target
├── arc/
│   ├── arc-runner-scale-set-helm-values-docaohieu2808.yaml
│   └── arc-runner-scale-set-install-on-k8s-crd-example.yaml
└── examples/
    ├── zero-config-minimal-ci-cd-usage.yml
    ├── custom-override-with-deploy-target-and-ci-config.yml
    └── dot-ci-yml-project-root-deploy-config-example.yml
```
