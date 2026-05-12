#!/bin/bash
set -Eeuo pipefail

#
# Wire
# Copyright (C) 2026 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CONFIG_PATH="${TESTSERVICE_CONFIG:-$REPO_ROOT/testservice/testservice-config.yml}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "ERROR: Config not found at $CONFIG_PATH"
  echo "Expected config at $REPO_ROOT/testservice/testservice-config.yml or set TESTSERVICE_CONFIG"
  exit 1
fi

STATE_DIR="${HOME}/Library/Caches/wire-local-testservice"
LOG_FILE="$STATE_DIR/testservice.log"
PID_FILE="$STATE_DIR/testservice.pid"
JAR_FILE="$STATE_DIR/testservice.jar"

mkdir -p "$STATE_DIR"

echo "== Script dir =="
echo "$SCRIPT_DIR"

echo "== Repo root =="
echo "$REPO_ROOT"

echo "== Config path =="
echo "$CONFIG_PATH"

echo "== Resolving Java 17 =="
if ! JAVA_17_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null)"; then
  echo "ERROR: Java 17 not found."
  echo "Install it via:"
  echo "  brew install --cask temurin@17"
  exit 1
fi

export JAVA_HOME="$JAVA_17_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

echo "JAVA_HOME=$JAVA_HOME"
java -version

echo "== Seeding simulator media =="
"$REPO_ROOT/scripts/seed-simulator-media.sh" || echo "WARNING: Failed to seed simulator media"

echo "== Cleaning previous local state =="
if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" || true)"
  if [[ -n "${OLD_PID:-}" ]]; then
    kill "$OLD_PID" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
fi

rm -f "$LOG_FILE"

DOWNLOAD_ARGS=(download --output "$JAR_FILE")
if [[ -n "${KALIUM_TESTSERVICE_REF:-}" ]]; then
  DOWNLOAD_ARGS+=(--ref "$KALIUM_TESTSERVICE_REF")
fi

python3 "$SCRIPT_DIR/kalium-testservice-jar.py" "${DOWNLOAD_ARGS[@]}"

echo "== Starting Kalium Testservice =="
echo "👉 Service will run at: http://localhost:8080"
echo "👉 Press Ctrl+C to stop"
echo "Log file: $LOG_FILE"

(
  for i in {1..90}; do
    if curl -fsS "http://localhost:8080/api/v1/instances" >/dev/null 2>&1; then
      echo "✅ Kalium Testservice reachable (after ${i}s)"
      exit 0
    fi
    sleep 1
  done

  echo "ERROR: Testservice not reachable after 90s"
  exit 1
) &
READY_PID=$!

cd "$REPO_ROOT"
java -jar "$JAR_FILE" server "$CONFIG_PATH" 2>&1 | tee "$LOG_FILE"

if ! wait "$READY_PID"; then
  READINESS_STATUS=$?
  echo "ERROR: Kalium Testservice readiness check failed (exit code: $READINESS_STATUS)"
  exit "$READINESS_STATUS"
fi
