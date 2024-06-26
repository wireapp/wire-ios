require 'json'

xcode_summary.inline_mode = true
xcode_summary.report 'xcodebuild-wire-ios.xcresult'

# add extra warning
result = xcode_summary.warning_error_count 'WireiOS.xcresult'
json_hash = JSON.parse(result, symbolize_names: true)

warnings_count = json_hash[:warnings]
errors_count = json_hash[:errors]

max_warnings = 359
# set current branch warnings count
if warnings_count < max_warnings 
    warn " You removed #{max_warnings - warnings_count} warnings !! please change max_warnings limit before merging"
elsif warnings_count == max_warnings 
    message "The whole team congratulates you, you did not make it worse, thanks!"
else 
    fail "#{warnings_count - max_warnings} warnings introduced - please fix them"
end
