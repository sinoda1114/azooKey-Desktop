#!/bin/sh
set -eu

service_name="dev.ensan.inputmethod.azooKeyMac.ConverterServer"
app_path="/Library/Input Methods/azooKeyMac.app"
server_path="${app_path}/Contents/Helpers/ConverterServer/ConverterServer"
agent_path="/Library/LaunchAgents/${service_name}.plist"

if [ ! -x "${server_path}" ]; then
    echo "ConverterServer not found: ${server_path}" >&2
    exit 1
fi

cat > "${agent_path}" <<PLIST
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

chmod 644 "${agent_path}"
chown root:wheel "${agent_path}"

console_user="$(stat -f %Su /dev/console)"
if [ -n "${console_user}" ] && [ "${console_user}" != "root" ] && [ "${console_user}" != "_mbsetupuser" ]; then
    console_uid="$(id -u "${console_user}")"
    launchctl bootout "gui/${console_uid}/${service_name}" >/dev/null 2>&1 || true
    launchctl bootstrap "gui/${console_uid}" "${agent_path}"
    launchctl kickstart -k "gui/${console_uid}/${service_name}"
fi

echo "Installed and started ${service_name}"
