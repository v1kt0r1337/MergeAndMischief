#!/usr/bin/env bash

set -e

# Edit these to fit your source (code project) and destination (game) script location. 
SRC="$HOME/projects/MMMerge-content-mod/Scripts/"
DST="$HOME/Games/Heroic/Might and Magic 8/Scripts/"

echo "Deploying mod files..."

rsync -av --delete "$SRC" "$DST"

echo "Done."