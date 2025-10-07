if [ -n "$TF_BUILD" ]; then
  echo "warning: Skipping Periphery: Running on CI"
  exit 0
fi

export PATH="$PATH:/opt/homebrew/bin"

echo "Ensuring Periphery v3+ is installed..."

PERIPHERY_PATH=$(command -v periphery)
CURRENT_MAJOR_VERSION=""

if [ -n "$PERIPHERY_PATH" ]; then
  # Periphery is installed, try to get its major version
  CURRENT_MAJOR_VERSION=$(periphery version 2>/dev/null | grep -oE '^[0-9]+')
fi

if [ -z "$PERIPHERY_PATH" ] || [ -z "$CURRENT_MAJOR_VERSION" ] || [ "$CURRENT_MAJOR_VERSION" -lt 3 ]; then
  # Periphery is not installed, or version could not be determined, or it's < v3
  if [ -n "$PERIPHERY_PATH" ]; then
    echo "Found Periphery version ${CURRENT_MAJOR_VERSION:-unknown}. Uninstalling old version..."
    brew uninstall periphery || true # Uninstall if present, ignore if not
    # If it was installed from a tap, untap it to ensure we get the core formula
    if brew tap | grep -q "peripheryapp/periphery"; then
      echo "Untapping peripheryapp/periphery to ensure installation from core Homebrew."
      brew untap peripheryapp/periphery || true
    fi
  else
    echo "Periphery not found."
  fi

  echo "Installing the latest Periphery (expected v3+)..."
  brew install periphery

  # Re-verify after installation
  PERIPHERY_VERSION_AFTER_INSTALL=$(periphery version 2>/dev/null | grep -oE '^[0-9]+')
  if [ -z "$PERIPHERY_VERSION_AFTER_INSTALL" ] || [ "$PERIPHERY_VERSION_AFTER_INSTALL" -lt 3 ]; then
    echo "Error: Periphery v3+ could not be installed. Detected version: ${PERIPHERY_VERSION_AFTER_INSTALL:-Not Found}" >&2
    exit 1
  else
    echo "Periphery version $PERIPHERY_VERSION_AFTER_INSTALL successfully installed."
  fi
else
  echo "Periphery version $CURRENT_MAJOR_VERSION is already installed and up-to-date."
fi

INDEX_STORE_PATH="${BUILD_DIR%Build/*}Index.noindex/DataStore"

cd ${WORKSPACE_DIR}

# To know what each param does check https://github.com/peripheryapp/periphery?tab=readme-ov-file#analysis
periphery scan \
--project wire-ios-mono.xcworkspace \
--schemes "Wire-iOS" \
--index-store-path "$INDEX_STORE_PATH" \
--retain-objc-accessible \
--retain-swift-ui-previews \
--retain-codable-properties \
--relative-results \
--format xcode \
--quiet \
