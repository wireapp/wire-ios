source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

gem 'fastlane'
gem 'git'
gem 'httparty'
gem 'xcode-install'
gem 'danger'
gem 'danger-xcode_summary'


plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
