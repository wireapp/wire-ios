#!/bin/bash

# Define output file path
OUTPUT_FILE="wire-ios/WireUITests/LoginCredentials.swift"

# Ensure the output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Check if running in CI
if [[ -n "$CI" ]]; then
  # Ensure the required environment variables are set in CI
  if [[ -z "${UI_TEST_LOGIN_EMAIL}" || -z "${UI_TEST_LOGIN_PASSWORD}" ]]; then
    echo "Error: UI_TEST_LOGIN_EMAIL and UI_TEST_LOGIN_PASSWORD must be set in CI."
    exit 1
  fi
else
  # Provide dummy values for local development
  UI_TEST_LOGIN_EMAIL="test@example.com"
  UI_TEST_LOGIN_PASSWORD="password123"
fi

# Generate the Swift file
cat > "$OUTPUT_FILE" <<EOF
//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

// Generated file - DO NOT EDIT
enum LoginCredentials {
    static let email: String = "${UI_TEST_LOGIN_EMAIL}"
    static let password: String = "${UI_TEST_LOGIN_PASSWORD}"
}
EOF

echo "Login credentials generated at $OUTPUT_FILE"
