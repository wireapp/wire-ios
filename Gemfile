source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

gem 'fastlane'
gem 'git'
gem 'httparty'
gem 'xcode-install'
gem 'mutex_m'
gem 'danger'
gem 'danger-xcodebuild'
gem 'danger-xcode_summary'


plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
