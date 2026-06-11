# reusable-workflows

**Tier:** GitHub Actions advanced (L5-6) — đỉnh của track GitHub Actions trong portfolio CI/CD.

**Vị trí trong learning path:**
```
test-gh-actions (L1) → gh-actions-test-express (L1.5) → reusable-workflows (L5-6)
```

## Mục đích

Zero-config CI/CD pipeline dưới dạng reusable workflow + composite actions + GitHub Marketplace action. Auto-detect ngôn ngữ → build → test → lint → security scan → deploy. Hỗ trợ ARC (Actions Runner Controller) self-hosted runners trên K8s.

## Cách dùng

### 1. Reusable workflow (khuyến nghị — dùng cho org nội bộ)

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

### 2. Composite action (dùng trong job của consumer)

```yaml
- uses: docaohieu2808/reusable-workflows@master
  with:
    deploy_target: ssh-build
    deploy_host: app.example.com
```

### 3. Individual composite actions

```yaml
- uses: docaohieu2808/reusable-workflows/actions/detect@master
- uses: docaohieu2808/reusable-workflows/actions/build@master
  with:
    language: node
    node_version: "20"
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

## Inputs (reusable workflow)

| Input | Default | Mô tả |
|-------|---------|-------|
| `node_version` | `20` | Node.js version |
| `java_version` | `17` | Java version |
| `go_version` | `1.22` | Go version |
| `python_version` | `3.12` | Python version |
| `skip_tests` | `false` | Bỏ qua unit tests |
| `skip_lint` | `false` | Bỏ qua lint |
| `skip_security` | `false` | Bỏ qua security scan |
| `deploy_target` | `` | Target deploy (xem deploy action) |
| `deploy_host` | `` | SSH host |
| `deploy_user` | `deploy` | SSH user |
| `deploy_path` | `/opt/app` | Remote path |
| `docker_registry` | `ghcr.io` | Docker registry |
| `docker_image` | `` | Docker image name |

## Secrets

| Secret | Dùng khi |
|--------|---------|
| `SSH_PRIVATE_KEY` | deploy_target là ssh-based |
| `DOCKER_REGISTRY_PASSWORD` | push Docker image |

## ARC Self-hosted Runners (K8s)

Xem `arc/` — scale set config cho Actions Runner Controller trên k3s/EKS/GKE.

## Demo points (interview)

- Một concept "zero-config auto-detect" implement trên 4 CI system (GH Actions / GitLab CI / Tekton / Jenkins)
- Composite action vs reusable workflow vs Marketplace action — 3 hình thức publish khác nhau của GH Actions
- ARC self-hosted runners — scale to zero, ephemeral, K8s-native
- Supply-chain: trivy pinned SHA, explicit secrets thay `secrets: inherit`
