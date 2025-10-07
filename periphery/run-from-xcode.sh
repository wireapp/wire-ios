if [ -n "$TF_BUILD" ]; then
  echo "warning: Skipping Periphery: Running on CI"
  exit 0
fi

export PATH="$PATH:/opt/homebrew/bin"

if ! [ -x "$(command -v periphery)" ]; then
  brew install periphery
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
