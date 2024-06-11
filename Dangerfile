xcode_summary.inline_mode = true
result = xcode_summary.warning_error_count 'MyWireiOS.xcresult'

warnings_count = result["warnings"]
errors_count = result["errors"]

max_warnings = 359
# set current branch warnings count
if warnings_count < max_warnings 
    warn "change max_warnings limit before merging"
else 
    fail "#{max_warnings - warnings_count} warnings introduced - please fix them"
end
