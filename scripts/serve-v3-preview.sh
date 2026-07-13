#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly project_root="$(cd "${script_dir}/.." && pwd)"
cd "${project_root}"

host="${V3_PREVIEW_HOST:-127.0.0.1}"
port="${V3_PREVIEW_PORT:-8090}"
slug="${V3_PREVIEW_SLUG:-button/V3MiniButton}"
readonly entrypoint="lib/preview_v3/main.dart"
readonly build_dir="build/web"
readonly build_marker="${build_dir}/main.dart.js"
readonly registry_generator="tool/generate_v3_preview_registry.dart"

usage() {
  cat <<'EOF'
Usage: scripts/serve-v3-preview.sh [--host HOST] [--port PORT] [--slug CATEGORY/WidgetClass]

Builds (only if the preview source changed) and serves the local Widget V3
preview host, then prints the exact preview URL once the HTTP server is
ready to accept requests. Stays in the foreground; stop with Ctrl-C.

Environment overrides: V3_PREVIEW_HOST, V3_PREVIEW_PORT, V3_PREVIEW_SLUG
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host="$2"
      shift 2
      ;;
    --port)
      port="$2"
      shift 2
      ;;
    --slug)
      slug="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter SDK not found on PATH. Install/activate Flutter before running this script." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 not found on PATH; it is used to serve ${build_dir} over HTTP." >&2
  exit 1
fi

if [[ ! -f "${entrypoint}" ]]; then
  echo "Error: preview entrypoint not found at ${entrypoint} (run from repo root)." >&2
  exit 1
fi

if [[ ! -f "${registry_generator}" ]]; then
  echo "Error: preview registry generator not found at ${registry_generator}." >&2
  exit 1
fi

if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Error: port ${port} is already in use:" >&2
  lsof -nP -iTCP:"${port}" -sTCP:LISTEN >&2
  echo "Stop that process or pick another port with --port or V3_PREVIEW_PORT." >&2
  exit 1
fi

echo "Refreshing Widget V3 preview registry..."
dart run "${registry_generator}"

needs_build=1
if [[ -f "${build_marker}" ]]; then
  stale="$({
    find lib web -type f -newer "${build_marker}" 2>/dev/null
    find pubspec.yaml pubspec.lock -type f -newer "${build_marker}" 2>/dev/null
  } | head -n 1)"
  if [[ -z "${stale}" ]]; then
    needs_build=0
  fi
fi

if [[ "${needs_build}" -eq 1 ]]; then
  echo "Building Widget V3 preview bundle (${entrypoint})..."
  flutter build web --release -t "${entrypoint}"
else
  echo "Reusing existing ${build_dir} bundle (no preview source changes detected)."
fi

server_pid=""
cleanup() {
  if [[ -n "${server_pid}" ]] && kill -0 "${server_pid}" 2>/dev/null; then
    kill "${server_pid}" 2>/dev/null || true
    wait "${server_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

(cd "${build_dir}" && exec python3 -m http.server "${port}" --bind "${host}") &
server_pid=$!

ready=0
for _ in $(seq 1 60); do
  if curl -sf -o /dev/null "http://${host}:${port}/"; then
    ready=1
    break
  fi
  if ! kill -0 "${server_pid}" 2>/dev/null; then
    echo "Error: preview HTTP server exited before becoming ready." >&2
    exit 1
  fi
  sleep 0.5
done

if [[ "${ready}" -ne 1 ]]; then
  echo "Error: preview HTTP server did not become ready at http://${host}:${port}/ within 30s." >&2
  exit 1
fi

echo "V3 preview ready: http://${host}:${port}/#/${slug}"

wait "${server_pid}"
