#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

command -v docker >/dev/null 2>&1 || {
  echo 'Docker is required. See INSTALL.txt.' >&2
  exit 1
}
if ! docker compose version >/dev/null 2>&1; then
  echo 'Docker Compose v2 is required.' >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
image_file="tg-signer-dashboard-${arch}.tar.gz"
test -f "$image_file" || { echo "Missing $image_file for this host" >&2; exit 1; }
sha256sum -c SHA256SUMS
docker load -i "$image_file"

mkdir -p data
chmod 700 data
if [ "$(id -u)" = 0 ]; then
  chown -R 10001:10001 data
else
  echo 'Run as root or make data writable by container UID 10001.' >&2
fi

docker compose up -d --no-build --pull never --wait dashboard
echo 'Dashboard is ready at http://127.0.0.1:8999'
if [ -f data/initial-password.txt ]; then
  echo 'First-use password: data/initial-password.txt'
fi
