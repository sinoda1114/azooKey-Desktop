#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
/bin/bash "$script_dir/personal-install-as-admin.sh"
read -r -p "完了しました。Enterキーで閉じます。"
