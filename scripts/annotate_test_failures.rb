#!/usr/bin/env ruby
# Parses JUnit XML test results and emits GitHub Actions error annotations.
require 'rexml/document'

files = Dir.glob('build/reports/*.junit') + Dir.glob('artifacts/**/*.junit')
files.each do |f|
  begin
    REXML::Document.new(File.read(f)).elements.each('//testcase') do |tc|
      next unless (failure = tc.elements['failure'])
      classname = tc.attributes['classname'] || ''
      name      = tc.attributes['name'] || 'Unknown'
      msg = (failure.attributes['message'] || failure.text || '')
              .gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
      title = "#{classname}.#{name}".gsub(',', '')
      puts "::error title=#{title}::#{msg}"
    end
  rescue => e
    warn "::warning::Cannot parse #{f}: #{e}"
  end
end
