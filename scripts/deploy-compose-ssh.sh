#!/usr/bin/env bash
# Deploy an image to a host that runs Docker Compose, over SSH.
#
# The host keeps its own compose file in DEPLOY_PATH and refers to the image as ${IMAGE}, for example
#   services:
#     app:
#       image: ${IMAGE}
# This script sets IMAGE to the new image reference, pulls it if missing, and recreates the services, waiting
# until their health checks pass. Pass an image by digest (name@sha256:...) so a deploy is exactly reproducible.
#
# Environment: DEPLOY_HOST, DEPLOY_USER, DEPLOY_PORT, DEPLOY_PATH, IMAGE (required); SSH_PRIVATE_KEY and
# SSH_KNOWN_HOSTS (required secrets); REGISTRY, REGISTRY_USERNAME, REGISTRY_PASSWORD (optional, to pull a
# private image).
set -euo pipefail

for v in DEPLOY_HOST DEPLOY_USER DEPLOY_PORT DEPLOY_PATH IMAGE SSH_PRIVATE_KEY SSH_KNOWN_HOSTS; do
  if [ -z "${!v:-}" ]; then echo "::error::$v is required"; exit 1; fi
done
# Host, user and path end up in an ssh command line; refuse anything that is not a plain name or path.
[[ "$DEPLOY_HOST" =~ ^[A-Za-z0-9.:-]+$ ]] || { echo "::error::DEPLOY_HOST has unexpected characters"; exit 1; }
[[ "$DEPLOY_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "::error::DEPLOY_USER has unexpected characters"; exit 1; }
[[ "$DEPLOY_PORT" =~ ^[0-9]+$ ]] || { echo "::error::DEPLOY_PORT must be a number"; exit 1; }
[[ "$DEPLOY_PATH" =~ ^/[A-Za-z0-9._/-]+$ ]] || { echo "::error::DEPLOY_PATH must be an absolute path"; exit 1; }

ssh_dir="$(mktemp -d)"
trap 'rm -rf "$ssh_dir"' EXIT
printf '%s\n' "$SSH_PRIVATE_KEY" > "$ssh_dir/key"
printf '%s\n' "$SSH_KNOWN_HOSTS" > "$ssh_dir/known_hosts"
chmod 600 "$ssh_dir/key" "$ssh_dir/known_hosts"
# Host keys are checked against SSH_KNOWN_HOSTS; an unknown or changed host key stops the deploy.
ssh_cmd=(ssh -i "$ssh_dir/key" -p "$DEPLOY_PORT" -o UserKnownHostsFile="$ssh_dir/known_hosts"
  -o StrictHostKeyChecking=yes -o BatchMode=yes "$DEPLOY_USER@$DEPLOY_HOST")

if [ -n "${REGISTRY_PASSWORD:-}" ]; then
  # The password travels on stdin, never on a command line where `ps` on the host could show it.
  printf '%s' "$REGISTRY_PASSWORD" |
    "${ssh_cmd[@]}" "docker login $(printf '%q' "${REGISTRY:-ghcr.io}") -u $(printf '%q' "${REGISTRY_USERNAME:?REGISTRY_USERNAME is required with REGISTRY_PASSWORD}") --password-stdin"
fi

"${ssh_cmd[@]}" "cd $(printf '%q' "$DEPLOY_PATH") && IMAGE=$(printf '%q' "$IMAGE") docker compose up -d --pull missing --remove-orphans --wait"
echo "Deployed $IMAGE to $DEPLOY_HOST:$DEPLOY_PATH"
