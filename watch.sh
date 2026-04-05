#!/usr/bin/env bash

trap 'echo "Stopping watcher."; exit 0' INT TERM

echo "Initial deploy..."
./deploy.sh

echo "Watching for changes..."

while true; do
  find Scripts -name "*.lua" | entr -rd ./deploy.sh || true
done