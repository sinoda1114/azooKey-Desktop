#!/bin/bash
set -euo pipefail

# Builds a Developer ID signed, Apple-notarized installer for personal use.
# Required once on this build Mac:
#   xcrun notarytool store-credentials azooKeyPersonalNotary ...

repository="sinoda1114/azooKey-Desktop"
asset_name="azooKeyPersonal.pkg"
release_tag="personal-$(/bin/date +%Y%m%d-%H%M%S)"
repository_root="$(cd "$(dirname "$0")/.." && pwd)"
temporary_dir="$(/usr/bin/mktemp -d -t azookey-personal-notarized-release)"
derived_data="${temporary_dir}/DerivedData"
payload_root="${temporary_dir}/payload"
scripts_dir="${temporary_dir}/scripts"
unsigned_pkg="${temporary_dir}/unsigned.pkg"
signed_pkg="${temporary_dir}/${asset_name}"
package_version="$(/bin/date +%Y%m%d%H%M)"

team_id="${DEVELOPMENT_TEAM_ID:-4F94FTUS6D}"
app_identity="${DEVELOPER_ID_APPLICATION_IDENTITY:?DEVELOPER_ID_APPLICATION_IDENTITY を設定してください}"
installer_identity="${DEVELOPER_ID_INSTALLER_IDENTITY:?DEVELOPER_ID_INSTALLER_IDENTITY を設定してください}"
notary_profile="${NOTARYTOOL_PROFILE:-azooKeyPersonalNotary}"

cleanup() {
    /bin/rm -rf "${temporary_dir}"
}
trap cleanup EXIT

cd "${repository_root}"
test -z "$(/usr/bin/git status --porcelain)"
test -f azooKeyMac/Resources/base_n5_lm/lm_c_abc.marisa
test -f azooKeyMac/Resources/gguf/ggml-model-Q5_K_M.gguf

/usr/bin/xcodebuild \
    -project azooKeyMac.xcodeproj \
    -scheme azooKeyMac \
    -configuration Release \
    -jobs 4 \
    -derivedDataPath "${derived_data}" \
    ARCHS=arm64 \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

app_path="${derived_data}/Build/Products/Release/azooKeyMac.app"
/usr/bin/codesign --force --deep --options runtime --timestamp --sign "${app_identity}" "${app_path}"
/usr/bin/codesign --verify --deep --strict --verbose=2 "${app_path}"

/bin/mkdir -p "${payload_root}/Library/Input Methods" "${scripts_dir}"
/usr/bin/ditto "${app_path}" "${payload_root}/Library/Input Methods/azooKeyMac.app"
/bin/cp Tools/personal-pkg-postinstall.sh "${scripts_dir}/postinstall"
/bin/chmod 755 "${scripts_dir}/postinstall"

/usr/bin/pkgbuild \
    --root "${payload_root}" \
    --scripts "${scripts_dir}" \
    --identifier dev.ensan.inputmethod.azooKeyMac.personal \
    --version "${package_version}" \
    --install-location / \
    "${unsigned_pkg}"

/usr/bin/productsign --sign "${installer_identity}" --timestamp "${unsigned_pkg}" "${signed_pkg}"
/usr/sbin/pkgutil --check-signature "${signed_pkg}"
/usr/bin/xcrun notarytool submit "${signed_pkg}" --keychain-profile "${notary_profile}" --wait
/usr/bin/xcrun stapler staple "${signed_pkg}"
/usr/bin/xcrun stapler validate "${signed_pkg}"

"$(/usr/bin/command -v gh)" release create "${release_tag}" "${signed_pkg}#${asset_name}" \
    --repo "${repository}" \
    --title "自分用あずき ${release_tag}" \
    --notes "Appleの公証済みインストーラです。ダウンロード後に ${asset_name} をダブルクリックしてインストールしてください。"

echo "公開完了: https://github.com/${repository}/releases/tag/${release_tag}"
