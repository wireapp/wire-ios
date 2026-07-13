#!/usr/bin/env ruby
# Parses JUnit XML test results and emits GitHub Actions error annotations.
require 'rexml/document'

def encode_property(str)
  str.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A').gsub(':', '%3A').gsub(',', '%2C')
end

def encode_data(str)
  str.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
end

files = Dir.glob('build/reports/*.junit') + Dir.glob('artifacts/**/*.junit')
files.each do |f|
  begin
    REXML::Document.new(File.read(f)).elements.each('//testcase') do |tc|
      next unless (failure = tc.elements['failure'])
      classname = tc.attributes['classname'] || ''
      name      = tc.attributes['name'] || 'Unknown'
      title = encode_property("#{classname}.#{name}")
      msg   = encode_data(failure.attributes['message'] || failure.text || '')
      puts "::error title=#{title}::#{msg}"
    end
  rescue => e
    warn "::warning::#{encode_data(e.to_s)}"
  end
end
