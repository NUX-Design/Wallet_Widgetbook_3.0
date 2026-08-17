#!/usr/bin/env bash
# Retry helper for `gh` calls in v3-preview-bundle.yml. GitHub's REST/GraphQL
# API occasionally returns transient 5xx errors (seen in practice as
# "HTTP 503: No server is currently available..." during partial outages);
# without a retry, one flaky response fails the whole publish job even
# though the underlying release/API call would have succeeded moments later.
#
# Usage: source this file, then call `retry_gh <command> [args...]`.

retry_gh() {
  local max_attempts=5
  local attempt=1
  local delay=5
  local stderr_file
  stderr_file="$(mktemp)"

  while true; do
    local status=0
    "$@" 2>"$stderr_file" || status=$?
    local err
    err="$(cat "$stderr_file")"
    cat "$stderr_file" >&2

    if [ "$status" -eq 0 ]; then
      rm -f "$stderr_file"
      return 0
    fi

    if ! grep -qE '(HTTP 5[0-9]{2}|No server is currently available|timed? ?out|connection reset|EOF|network is unreachable)' <<<"$err"; then
      echo "retry_gh: non-transient failure (exit ${status}); not retrying: $*" >&2
      rm -f "$stderr_file"
      return "$status"
    fi
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "retry_gh: giving up after ${attempt} attempts: $*" >&2
      rm -f "$stderr_file"
      return "$status"
    fi
    echo "retry_gh: attempt ${attempt} failed with a transient error (exit ${status}); retrying in ${delay}s: $*" >&2
    sleep "$delay"
    attempt=$((attempt + 1))
    delay=$((delay * 2))
  done
}
