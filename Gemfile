source 'https://rubygems.org'

gem 'fastlane'
gem 'git'
gem 'httparty'
gem "xcode-install"

# warning: no longer be part of the default gems since Ruby 3.4.0.
gem 'abbrev' # required by highline-2.0.3
gem 'mutex_m' # required by httpclient-2.8.3

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
