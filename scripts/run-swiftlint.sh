# Adds support for Apple Silicon brew directory
export PATH="$PATH:/opt/homebrew/bin"
 
if [ -z "$CI" ]; then
  if which swiftlint >/dev/null; then
    swiftlint --config ../.swiftlint.yml
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
else
  echo "Skipping SwiftLint in CI environment"
fi
