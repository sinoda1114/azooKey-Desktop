#!/bin/bash
set -euo pipefail

source_app="$(cd "$(dirname "$0")" && pwd)/azooKeyMac.app"
target_app="/Library/Input Methods/azooKeyMac.app"
staging_app="/Library/Input Methods/azooKeyMac.app.personal-staging"
backup_app="/Library/Input Methods/azooKeyMac.app.before-personal-update-$(/bin/date +%Y%m%d-%H%M%S)"
service_name="dev.ensan.inputmethod.azooKeyMac.ConverterServer"
agent_path="/Library/LaunchAgents/${service_name}.plist"

test -d "$source_app"
test ! -e "$staging_app"
/usr/bin/codesign --verify --deep --strict "$source_app"

/usr/bin/ditto "$source_app" "$staging_app"
/usr/sbin/chown -R root:wheel "$staging_app"
/usr/bin/codesign --verify --deep --strict "$staging_app"

if [ -e "$target_app" ]; then
    /bin/mv "$target_app" "$backup_app"
fi
if ! /bin/mv "$staging_app" "$target_app"; then
    if [ -e "$backup_app" ]; then
        /bin/mv "$backup_app" "$target_app"
    fi
    exit 1
fi
/usr/bin/codesign --verify --deep --strict "$target_app"

server_path="${target_app}/Contents/Helpers/ConverterServer/ConverterServer"
test -x "$server_path"
/bin/cat > "$agent_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${service_name}</string>
    <key>ProgramArguments</key>
    <array><string>${server_path}</string></array>
    <key>MachServices</key>
    <dict><key>${service_name}</key><true/></dict>
    <key>KeepAlive</key><true/>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
PLIST
/bin/chmod 644 "$agent_path"
/usr/sbin/chown root:wheel "$agent_path"

console_user="$(/usr/bin/stat -f %Su /dev/console)"
if [ -n "$console_user" ] && [ "$console_user" != "root" ] && [ "$console_user" != "_mbsetupuser" ]; then
    console_uid="$(/usr/bin/id -u "$console_user")"
    /bin/launchctl bootout "gui/${console_uid}/${service_name}" 2>/dev/null || true
    /bin/launchctl bootstrap "gui/${console_uid}" "$agent_path"
    /bin/launchctl kickstart -k "gui/${console_uid}/${service_name}"
fi
echo "インストール完了: ${target_app}"
