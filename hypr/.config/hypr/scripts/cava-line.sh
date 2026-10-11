#!/usr/bin/env bash
# Hides the cava line in hyprlock when nothing is playing
playerctl status >/dev/null 2>&1 && tail -n 1 /tmp/cava-bars 2>/dev/null