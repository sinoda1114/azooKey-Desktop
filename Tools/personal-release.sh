#!/bin/bash
set -euo pipefail

repository="sinoda1114/azooKey-Desktop"
asset_name="azooKeyPersonal.zip"
release_tag="personal-$(/bin/date +%Y%m%d-%H%M%S)"
repository_root="$(cd "$(dirname "$0")/.." && pwd)"
temporary_dir="$(/usr/bin/mktemp -d -t azookey-personal-release)"
derived_data="$temporary_dir/DerivedData"
release_dir="$temporary_dir/release"
trap '/bin/rm -rf "$temporary_dir"' EXIT

cd "$repository_root"
test -z "$(/usr/bin/git status --porcelain)"
test -f azooKeyMac/Resources/base_n5_lm/lm_c_abc.marisa
test -f azooKeyMac/Resources/gguf/ggml-model-Q5_K_M.gguf

/usr/bin/xcodebuild -project azooKeyMac.xcodeproj -scheme azooKeyMac -configuration Debug -jobs 4 \
    -derivedDataPath "$derived_data" \
    DEVELOPMENT_TEAM=4F94FTUS6D CODE_SIGN_IDENTITY="Apple Development" \
    -allowProvisioningUpdates build

/bin/mkdir -p "$release_dir"
/usr/bin/ditto "$derived_data/Build/Products/Debug/azooKeyMac.app" "$release_dir/azooKeyMac.app"
/bin/cp Tools/personal-install-as-admin.sh "$release_dir/personal-install-as-admin.sh"
/bin/cp Tools/personal-update.sh "$release_dir/personal-update.sh"
/bin/cp "Tools/Install Personal azooKey.command" "$release_dir/Install Personal azooKey.command"
/bin/cp "Tools/Update Personal azooKey.command" "$release_dir/Update Personal azooKey.command"
/bin/chmod 755 "$release_dir"/*.sh "$release_dir"/*.command
/usr/bin/codesign --verify --deep --strict "$release_dir/azooKeyMac.app"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$release_dir" "$temporary_dir/$asset_name"

"$(/usr/bin/command -v gh)" release create "$release_tag" "$temporary_dir/$asset_name#$asset_name" \
    --repo "$repository" --title "自分用あずき $release_tag" \
    --notes "機能を統合したApple Silicon用の自分用ビルドです。初回は展開して Install Personal azooKey.command をダブルクリックし、以後は Update Personal azooKey.command を実行してください。"

echo "公開完了: https://github.com/${repository}/releases/tag/${release_tag}"
