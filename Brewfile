tap "peripheryapp/periphery"

# Common dependencies for both CI and local development
brew "git-lfs"

# CI-only dependencies
brew "imagemagick" if ENV['CI']
brew "ghostscript" if ENV['CI']

# Development-only dependencies
brew "periphery" unless ENV['CI'] # no version support for periphery, using the latest
