source 'https://rubygems.org'

gem 'fastlane'
gem 'abbrev' # required by highline-2.0.3, but not part of default gems since Ruby 3.4.0.
gem 'git'
gem 'httparty'
gem "xcode-install"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
