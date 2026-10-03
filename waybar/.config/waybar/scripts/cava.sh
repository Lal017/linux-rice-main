#!/bin/bash
export LC_ALL=C.UTF-8   # make ${bars:$h:1} index characters, not bytes

bars="▁▂▃▄▅▆▇█"

counter=0
player_active=true

stdbuf -oL cava -p "$HOME/.config/cava/waybar.conf" | while read -r line; do
    counter=$((counter + 1))
    if [ $((counter % 30)) -eq 0 ]; then
        if playerctl status &>/dev/null; then
            player_active=true
        else
            player_active=false
        fi
    fi

    if [ "$player_active" = true ]; then
        output=""
        IFS=';' read -ra heights <<< "$line"
        for h in "${heights[@]}"; do
            [ -z "$h" ] && continue
            output+="${bars:$h:1}"
        done
        echo "$output"
    else
        echo ""
    fi
done