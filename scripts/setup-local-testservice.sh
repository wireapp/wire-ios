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

STATE_DIR="${TMPDIR:-/tmp}/wire-local-testservice"
KALIUM_DIR="$STATE_DIR/kalium"
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

rm -f "$LOG_FILE" "$JAR_FILE"
rm -rf "$KALIUM_DIR"

echo "== Resolving Kalium testservice ref =="
DEFAULT_KALIUM_REF="5ec1c95b75daa7241e38c97f2916a06a2e40ce1b"
KALIUM_REF="${KALIUM_TESTSERVICE_REF:-$DEFAULT_KALIUM_REF}"

if [[ -z "$KALIUM_REF" ]]; then
  echo "ERROR: Could not resolve Kalium testservice ref"
  exit 1
fi

if [[ ! "$KALIUM_REF" =~ ^test-service-v[0-9]+\.[0-9]+\.[0-9]+$ && ! "$KALIUM_REF" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: Invalid Kalium testservice ref: $KALIUM_REF"
  exit 1
fi

echo "Using Kalium testservice ref: $KALIUM_REF"

echo "== Cloning Kalium =="
if [[ "$KALIUM_REF" =~ ^[0-9a-f]{40}$ ]]; then
  git init "$KALIUM_DIR"
  git -C "$KALIUM_DIR" remote add origin https://github.com/wireapp/kalium.git
  git -C "$KALIUM_DIR" fetch --depth 1 origin "$KALIUM_REF"
  git -C "$KALIUM_DIR" checkout --detach FETCH_HEAD
else
  git clone --depth 1 --branch "$KALIUM_REF" https://github.com/wireapp/kalium.git "$KALIUM_DIR"
fi

echo "== Kalium HEAD =="
git -C "$KALIUM_DIR" rev-parse HEAD

echo "== Building fat jar =="
cd "$KALIUM_DIR"
./gradlew --no-daemon --parallel :tools:testservice:shadowJar

echo "== Locating fat jar =="
BUILT_JAR="$(ls -1 "$KALIUM_DIR/tools/testservice/build/libs/"*"-all.jar" | head -n 1)"

if [[ -z "$BUILT_JAR" || ! -f "$BUILT_JAR" ]]; then
  echo "ERROR: Fat jar not found after build"
  ls -la "$KALIUM_DIR/tools/testservice/build/libs" || true
  exit 1
fi

cp "$BUILT_JAR" "$JAR_FILE"
echo "Using jar: $JAR_FILE"

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

  echo "ERROR: Testservice not reachable after 90s" >&2
  exit 1
) &
READY_PID=$!

cd "$REPO_ROOT"
java -jar "$JAR_FILE" server "$CONFIG_PATH" 2>&1 | tee "$LOG_FILE"

if ! wait "$READY_PID"; then
  READINESS_STATUS=$?
  echo "ERROR: Kalium Testservice readiness check failed (exit code: $READINESS_STATUS)" >&2
  exit "$READINESS_STATUS"
fi
