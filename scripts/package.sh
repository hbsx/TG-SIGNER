#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

image_arch="$(docker image inspect tg-signer-dashboard:local --format '{{.Architecture}}')"
if [ "$image_arch" != "$arch" ]; then
  echo "Image architecture $image_arch does not match host $arch" >&2
  exit 1
fi

# Export the verified image; persistent data is never included.
for required in docker-compose.yml release/install.sh release/INSTALL.txt; do
  test -f "$required" || { echo "Missing $required" >&2; exit 1; }
done
cp docker-compose.yml release/docker-compose.yml
image_file="tg-signer-dashboard-${arch}.tar.gz"
bundle_file="tg-signer-dashboard-vps-${arch}.tar.gz"
docker save tg-signer-dashboard:local | gzip -1 > "release/${image_file}.tmp"
mv "release/${image_file}.tmp" "release/${image_file}"
cd release

# Keep editable installation settings out of the install-time checksum list.
# The complete archive checksum still covers docker-compose.yml.
sha256sum "$image_file" docker-compose.yml install.sh INSTALL.txt > SHA256SUMS
chmod 644 "$image_file" docker-compose.yml INSTALL.txt SHA256SUMS
chmod 755 install.sh
tar -czf "${bundle_file}.tmp" \
  --owner=0 --group=0 --transform='s,^,tg-signer-dashboard/,' \
  "$image_file" docker-compose.yml install.sh INSTALL.txt SHA256SUMS
mv "${bundle_file}.tmp" "$bundle_file"
sha256sum "$bundle_file" > "${bundle_file}.sha256"
sha256sum "$image_file" > "${image_file}.sha256"
chmod 644 "$bundle_file" "${bundle_file}.sha256" "${image_file}.sha256"
echo "部署包：$PWD/$bundle_file"
