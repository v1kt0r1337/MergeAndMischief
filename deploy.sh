#!/usr/bin/env bash

set -e

# Edit these to fit your source (code project) and destination (game) script location.
SRC="$HOME/projects/MMMerge-content-mod/Scripts/"
DST="$HOME/Games/Heroic/Might and Magic 8/Scripts/"
MANIFEST="$HOME/projects/MMMerge-content-mod/.deployed_files"

echo "Deploying mod files..."

# Delete mod files that were deployed before but no longer exist in SRC
if [ -f "$MANIFEST" ]; then
    while IFS= read -r rel; do
        if [ ! -f "${SRC}${rel}" ]; then
            echo "Removing deleted mod file: $rel"
            rm -f "${DST}${rel}"
        fi
    done < "$MANIFEST"
fi

# Copy all mod files to DST
rsync -av "$SRC" "$DST"

# Update manifest with current SRC file list (relative paths)
find "$SRC" -type f | sed "s|${SRC}||" | sort > "$MANIFEST"

echo "Done."
