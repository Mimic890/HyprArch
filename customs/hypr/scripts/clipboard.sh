#!/bin/bash
cliphist list | wofi --dmenu --prompt "Clipboard history:" | cliphist decode | wl-copy
