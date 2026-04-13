tap "peripheryapp/periphery"

# Common dependencies for both CI and local development
brew "git-lfs"

# Development-only dependencies
brew "periphery" unless ENV['CI'] # no version support for periphery, using the latest
