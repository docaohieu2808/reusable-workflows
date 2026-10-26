# reusable-workflows

[![self-test](https://github.com/docaohieu2808/reusable-workflows/actions/workflows/self-test.yml/badge.svg)](https://github.com/docaohieu2808/reusable-workflows/actions/workflows/self-test.yml)

A zero-config CI/CD pipeline for GitHub Actions. It detects the project's language (Node, Java, Go, Python, PHP,
Rust), then builds, tests, lints, scans and optionally deploys, with nothing to configure for the common case.

It ships in three forms, so a team can adopt as much as it wants:

1. a **reusable workflow** (`.github/workflows/auto-pipeline.yml`) a repository calls in one line;
2. a **composite action** (`action.yml`) to drop into an existing job;
3. the **individual actions** (`actions/detect`, `build`, `test`, `deploy`) to compose by hand.

## Usage

### 1. Reusable workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD
on: [push, pull_request]
jobs:
  pipeline:
    uses: docaohieu2808/reusable-workflows/.github/workflows/auto-pipeline.yml@master
    secrets:
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
      DOCKER_REGISTRY_PASSWORD: ${{ secrets.DOCKER_REGISTRY_PASSWORD }}
    with:
      deploy_target: docker-compose        # optional
      deploy_host: app.example.com         # optional
```

### 2. Composite action

```yaml
- uses: docaohieu2808/reusable-workflows@master
  with:
    deploy_target: ssh-build
    deploy_host: app.example.com
```

### 3. Individual actions

```yaml
- uses: docaohieu2808/reusable-workflows/actions/detect@master
- uses: docaohieu2808/reusable-workflows/actions/build@master
  with:
    language: node
    node_version: "22"
- uses: docaohieu2808/reusable-workflows/actions/test@master
  with:
    language: node
- uses: docaohieu2808/reusable-workflows/actions/deploy@master
  with:
    deploy_target: docker-compose
    deploy_host: app.example.com
  env:
    SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
```

More in `examples/`.

## Deploy targets

`ssh-build`, `docker-compose`, `rsync`, `s3-cloudfront`, `k8s`, `helm`, `vercel`, `netlify`, `fly-io`, `railway`.

## Inputs (reusable workflow)

| Input | Default | Meaning |
|-------|---------|-------|
| `node_version` | `20` | Node.js version |
| `java_version` | `17` | Java version |
| `go_version` | `1.22` | Go version |
| `python_version` | `3.12` | Python version |
| `skip_tests` | `false` | Skip unit tests |
| `skip_lint` | `false` | Skip lint |
| `skip_security` | `false` | Skip the security scan |
| `deploy_target` | `` | Deploy target (see below) |
| `deploy_host` | `` | SSH host |
| `deploy_user` | `deploy` | SSH user |
| `deploy_path` | `/opt/app` | Remote path |
| `docker_registry` | `ghcr.io` | Docker registry |
| `docker_image` | `` | Docker image name |

## Secrets

| Secret | Needed when |
|--------|---------|
| `SSH_PRIVATE_KEY` | the deploy target uses SSH |
| `DOCKER_REGISTRY_PASSWORD` | pushing a Docker image |

## Self-hosted runners on Kubernetes

`arc/` holds the scale-set configuration for Actions Runner Controller: ephemeral runners that scale to zero on
k3s, EKS or GKE.

## Design notes

- **Secrets are passed explicitly**, never with `secrets: inherit`, so a caller hands over only what a step uses.
- **The security scan is pinned by commit SHA.** On 2026-03-19 the `aquasecurity/trivy-action` tags were
  force-pushed to credential-stealing code (CVE-2026-33634); a pinned SHA cannot be moved that way.
- **Checked on every push** (`.github/workflows/self-test.yml`): actionlint over every workflow, and the detect,
  build and test actions run against a small Node project in `tests/fixtures/node`.

## License

MIT, see [LICENSE](LICENSE).
