#!/usr/bin/env bash
set -euo pipefail

# Fresh installation from this fork's verified release bundle.
repo='hbsx/TG-SIGNER'
install_dir="${INSTALL_DIR:-/opt/tg-signer}"
release_tag="${RELEASE_TAG:-latest}"

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [ "$(id -u)" != 0 ]; then
  echo 'Run this installer as root.' >&2
  exit 1
fi
if [ -d "$install_dir" ] && [ -n "$(find "$install_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Installation directory is not empty: $install_dir" >&2
  echo 'Back up existing data and update it manually; this script is for fresh installations.' >&2
  exit 1
fi

bundle="tg-signer-dashboard-vps-${arch}.tar.gz"
if [ "$release_tag" = latest ]; then
  base_url="https://github.com/${repo}/releases/latest/download"
else
  base_url="https://github.com/${repo}/releases/download/${release_tag}"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
curl -fLsS --retry 3 -o "$tmpdir/$bundle" "$base_url/$bundle"
curl -fLsS --retry 3 -o "$tmpdir/${bundle}.sha256" "$base_url/${bundle}.sha256"
(cd "$tmpdir" && sha256sum -c "${bundle}.sha256")
mkdir "$tmpdir/stage"
tar -xzf "$tmpdir/$bundle" -C "$tmpdir/stage" --strip-components=1
(cd "$tmpdir/stage" && sha256sum -c SHA256SUMS)
mkdir -p "$install_dir"
cp -a "$tmpdir/stage/." "$install_dir/"
bash "$install_dir/install.sh"
