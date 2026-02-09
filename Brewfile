tap "peripheryapp/periphery"

# Common dependencies for both CI and local development
brew "git-lfs"

# CI-only dependencies (install with: brew bundle --no-lock)
brew "imagemagick" if ENV['CI']
brew "ghostscript" if ENV['CI']

# Development-only dependencies (install with: brew bundle --no-lock)
brew "periphery" unless ENV['CI'] # no version support for periphery, using the latest
