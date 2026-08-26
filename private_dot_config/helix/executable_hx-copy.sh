#!/bin/sh

if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    exec wl-copy
fi

if [ -n "${DISPLAY:-}" ]; then
    if command -v xclip >/dev/null 2>&1; then
        exec xclip -selection clipboard
    fi

    if command -v xsel >/dev/null 2>&1; then
        exec xsel --clipboard --input
    fi
fi

printf '%s\n' 'hx-copy.sh: no supported clipboard backend found' >&2
exit 1
