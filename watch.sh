#!/usr/bin/env bash

set -e

echo "Initial deploy..."
./deploy.sh

echo "Watching for changes..."

while true; do
  find Scripts -name "*.lua" | entr -rd ./deploy.sh
done