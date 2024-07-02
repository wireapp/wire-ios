xcode_summary.inline_mode = true
xcode_summary.test_summary = false
xcode_summary.report ENV["XCRESULT_PATH"]
xcode_summary.ignored_results { |result|
  result.message.include? 'no NSValueTransformer with class name \'ExtendedSecureUnarchiveFromData\' was found for attribute'
}
