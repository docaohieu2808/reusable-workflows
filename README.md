# reusable-workflows

[![self-test](https://github.com/docaohieu2808/reusable-workflows/actions/workflows/self-test.yml/badge.svg)](https://github.com/docaohieu2808/reusable-workflows/actions/workflows/self-test.yml)

Zero-config CI/CD for GitHub Actions. It detects the stack (Node, Python, Go, Java, PHP or Rust), then installs,
builds, lints, tests, scans for vulnerable dependencies and committed secrets, builds the Docker image when there
is a Dockerfile, and can push it and deploy it with Docker Compose over SSH.

The behaviour described here is exercised by [`self-test`](.github/workflows/self-test.yml) on every push and
once a week, including the failure cases: a failing test, a known-vulnerable dependency and a leaked token must each
turn it red. The deploy step is tested end to end through `actions/deploy`; the workflow's deploy job itself needs a
real host and is not run, so a new toolchain or action release that breaks the pipeline shows up here first.

## Use it

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
permissions:
  contents: read
jobs:
  pipeline:
    uses: docaohieu2808/reusable-workflows/.github/workflows/auto-pipeline.yml@879b76e3e519725f0bfaea657865182b72addf4f # v2.0.1
```

That is the whole file for most repositories. Pin a commit SHA, not a tag or branch: a SHA cannot be moved under
you. `examples/` has a build, push and deploy setup.

## What runs

| Job | What it does | Fails when |
|---|---|---|
| detect | Picks the language from `package.json`, `pom.xml`/`build.gradle`, `go.mod`, `pyproject.toml`/`requirements.txt`, `composer.json` or `Cargo.toml`, and the Node package manager from the lockfile | No manifest is found (set `language`) |
| ci | Sets up the toolchain with caching, installs dependencies, builds, lints, tests | Any build, lint or test command fails |
| security | Trivy over the dependencies; gitleaks over the working tree | A fixable HIGH/CRITICAL vulnerability, or a secret |
| docker | Builds the image (tags: commit SHA, branch, PR); pushes only on the default branch when `push_image` is on | The build fails |
| deploy | Points a Compose project on the host at the new image (by digest) and waits for its health checks | SSH, the pull or a health check fails |

Per language:

| | Build | Lint | Test |
|---|---|---|---|
| Node (npm, pnpm, yarn) | `ci`/`install`, `run build` if defined | `run lint` if defined | `test` if defined |
| Python | `pip install -e ".[test]"` and requirements files | ruff | pytest |
| Go | `go build ./...` | `go vet`, staticcheck | `go test -race ./...` |
| Java (Maven, Gradle) | `package` / `build`, tests skipped | (add Checkstyle or SpotBugs to the build) | `verify` / `test` |
| PHP | `composer install` | `php -l` | PHPUnit |
| Rust | `cargo build` | `cargo fmt --check`, clippy `-D warnings` | `cargo test` |

A project with no tests passes with a warning. A failing test always fails the job: the self-test runs every
stack's tests once more with a forced failure and requires the job to go red.

## Inputs

| Input | Default | |
|---|---|---|
| `working_directory` | `.` | Project directory, for monorepos |
| `language` | detected | Skip detection |
| `node_version` / `python_version` / `go_version` / `java_version` / `php_version` | `24` / `3.14` / `stable` / `25` / `8.5` | An `.nvmrc`/`.node-version` or the `go` line in `go.mod` wins |
| `skip_lint`, `skip_tests`, `skip_security` | `false` | |
| `image` | `ghcr.io/<owner>/<repo>` | Image to build |
| `push_image` | `false` | Push on pushes to the default branch; the caller grants `packages: write` |
| `deploy` | `false` | Deploy the pushed image |
| `deploy_host`, `deploy_user`, `deploy_port`, `deploy_path` | —, `deploy`, `22`, `/opt/app` | The host keeps `compose.yaml` in `deploy_path` with `image: ${IMAGE}` |
| `environment` | `production` | Add required reviewers to this environment to approve each deploy |

Secrets (all optional, passed explicitly, never `secrets: inherit`): `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS` for
deploys; `DEPLOY_REGISTRY_USERNAME`/`DEPLOY_REGISTRY_PASSWORD` so the host can pull a private image (use a read-only
token); `REGISTRY_USERNAME`/`REGISTRY_PASSWORD` to push to a registry other than ghcr.io, which uses the job's
`GITHUB_TOKEN`.

## Using the actions directly

`actions/detect`, `setup`, `build`, `lint`, `test`, `scan` and `deploy` can be used one by one in your own job; each takes
`working-directory`, and the build, lint and test steps take the `language` and `package_manager` that detect
outputs. The logic lives in `scripts/`, so the workflow and the actions run the same code.

## Design notes

- **Every third-party action is pinned to a commit SHA.** On 2026-03-19 the `aquasecurity/trivy-action` tags were
  force-pushed to credential-stealing code (CVE-2026-33634); a SHA cannot be moved that way. The self-test checks
  that every pin is a real commit (an annotated tag's SHA looks the same but fails at run time), and Dependabot
  moves the pins weekly.
- **The workflow runs its own version of the actions.** Each job checks this repository out at `job.workflow_sha`,
  the commit the caller pinned, instead of calling the actions `@master`.
- **Nothing swallows a failure.** No `|| true` around builds or tests; linter and test-tool versions are pinned so
  an upstream release cannot change the result on its own.
- **Deploys check the host key** against `SSH_KNOWN_HOSTS` instead of trusting whatever answers, take the image by
  digest, run one at a time per environment, and pass registry passwords on stdin, not on a command line.
- **Least privilege:** every job reads only, except the image job, which uses what the caller grants (add
  `packages: write` only when pushing). The self-test calls the pipeline both ways, so a job that asks for more
  than a read-only caller gives fails here first.

## Self-hosted runners on Kubernetes

`arc/` holds an Actions Runner Controller scale set (Helm values and the equivalent manifest) that scales to zero
when idle. It is a reference configuration and is not exercised by the self-test.

## License

MIT, see [LICENSE](LICENSE).
