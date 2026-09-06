#!/bin/bash
set -euo pipefail

repository="sinoda1114/azooKey-Desktop"
asset_url="https://github.com/${repository}/releases/latest/download/azooKeyPersonal.zip"
temporary_dir="$(/usr/bin/mktemp -d -t azookey-personal-update)"
trap '/bin/rm -rf "$temporary_dir"' EXIT

/usr/bin/curl --fail --location --silent --show-error "$asset_url" --output "$temporary_dir/azooKeyPersonal.zip"
/usr/bin/ditto -x -k "$temporary_dir/azooKeyPersonal.zip" "$temporary_dir/release"
installer="$temporary_dir/release/release/personal-install-as-admin.sh"
test -x "$installer"

/usr/bin/osascript -e 'on run argv' -e 'do shell script "/bin/bash " & quoted form of (item 1 of argv) with administrator privileges' -e 'end run' "$installer"
echo "最新版へ更新しました。入力ソースの反映が遅い場合はログアウトして再ログインしてください。"
