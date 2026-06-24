#!/usr/bin/env ruby
# Parses JUnit XML test results and emits GitHub Actions error annotations.
require 'rexml/document'

<<<<<<< HEAD
=======
def encode_property(str)
  str.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A').gsub(':', '%3A').gsub(',', '%2C')
end

def encode_data(str)
  str.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
end

>>>>>>> eaa2b61476 (chore: inline xcresult analysis, remove per-framework macOS runners - WPB-26561 (#4913))
files = Dir.glob('build/reports/*.junit') + Dir.glob('artifacts/**/*.junit')
files.each do |f|
  begin
    REXML::Document.new(File.read(f)).elements.each('//testcase') do |tc|
      next unless (failure = tc.elements['failure'])
      classname = tc.attributes['classname'] || ''
      name      = tc.attributes['name'] || 'Unknown'
<<<<<<< HEAD
      msg = (failure.attributes['message'] || failure.text || '')
              .gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
      title = "#{classname}.#{name}".gsub(',', '')
      puts "::error title=#{title}::#{msg}"
    end
  rescue => e
    warn "::warning::Cannot parse #{f}: #{e}"
=======
      title = encode_property("#{classname}.#{name}")
      msg   = encode_data(failure.attributes['message'] || failure.text || '')
      puts "::error title=#{title}::#{msg}"
    end
  rescue => e
    warn "::warning::#{encode_data(e.to_s)}"
>>>>>>> eaa2b61476 (chore: inline xcresult analysis, remove per-framework macOS runners - WPB-26561 (#4913))
  end
end
