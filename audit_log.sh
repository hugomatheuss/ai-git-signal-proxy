#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/home/node/.openclaw/workspace/basis/scripts/commands.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
COMMAND="$*"

{
  echo "[$TIMESTAMP] $COMMAND"
} >> "$LOG_FILE"
