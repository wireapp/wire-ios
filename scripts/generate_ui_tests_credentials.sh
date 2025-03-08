#!/bin/bash

# Define output file path
OUTPUT_FILE="../wire-ios/WireUITests/LoginCredentials.swift"

# Ensure the output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Check if running in CI
if [[ -n "$CI" ]]; then
  # Ensure the required environment variables are set in CI
  if [[ -z "${LOGIN_EMAIL}" || -z "${LOGIN_PASSWORD}" ]]; then
    echo "Error: LOGIN_EMAIL and LOGIN_PASSWORD must be set in CI."
    exit 1
  fi
else
  # Provide dummy values for local development
  LOGIN_EMAIL="test@example.com"
  LOGIN_PASSWORD="password123"
fi

# Generate the Swift file
cat > "$OUTPUT_FILE" <<EOF
// Generated file - DO NOT EDIT
struct LoginCredentials {
    static let email: String = "${LOGIN_EMAIL}"
    static let password: String = "${LOGIN_PASSWORD}"
}
EOF

echo "Login credentials generated at $OUTPUT_FILE"
