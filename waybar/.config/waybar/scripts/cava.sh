#!/bin/bash

bars="▁▂▃▄▅▆▇█"

stdbuf -oL cava -p ~/.config/cava/waybar.conf | while read -r line; do
    output=""
    IFS=';' read -ra heights <<< "$line"
    for h in "${heights[@]}"; do
        [ -z "$h" ] && continue
        output+="${bars:$h:1}"
    done
    echo "$output"
done