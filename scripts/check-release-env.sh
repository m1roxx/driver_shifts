#!/usr/bin/env bash
# make apk and the release workflow: stops a release build whose API address is missing or not
# HTTPS (D12). Such an APK installs and opens, and then every request fails on the driver's phone.
# Usage: scripts/check-release-env.sh [env file, relative to the repository root]
set -euo pipefail

cd "$(dirname "$0")/.."

readonly env_file=${1:-app/env/prod.json}
readonly https_url='^https://[^/?#@[:space:]]+'

fail() {
  if [[ ${GITHUB_ACTIONS:-} == true ]]; then
    echo "::error title=Release API address::$*"
  fi
  echo "check-release-env: $*" >&2
  exit 1
}

[[ -f $env_file ]] ||
  fail "$env_file is missing. Add it with {\"API_BASE_URL\": \"https://<backend host>\"}" \
    "(docs/architecture.md, «Окружения»)."

url=$(jq --exit-status --raw-output '.API_BASE_URL | strings' "$env_file" 2>/dev/null) ||
  fail "$env_file must be a JSON object with a string API_BASE_URL."

[[ $url =~ $https_url ]] ||
  fail "API_BASE_URL in $env_file is \"$url\": a release APK talks to the backend over HTTPS only (D12)."

echo "check-release-env: $env_file → $url"
