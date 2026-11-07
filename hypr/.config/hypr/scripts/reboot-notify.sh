#!/usr/bin/env bash
# Keeps a critical notification up while a reboot is pending.
while true; do
    if [ -f /run/reboot-required ] || [ ! -d "/usr/lib/modules/$(uname -r)" ]; then
        reasons="$(cat /run/reboot-required 2>/dev/null)"
        notify-send -u critical \
            -h string:x-dunst-stack-tag:reboot-required \
            "Reboot required" "${reasons:-The kernel was updated}"
    fi
    sleep 600
done