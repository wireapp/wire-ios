#!/bin/bash
set -Eeuo pipefail

#
# Wire
# Copyright (C) 2026 Wire Swiss GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#

XCRESULT_SEARCH_PATH="${1:-artifacts}"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "ALLURE_REPORT_AVAILABLE=false" >> "${GITHUB_ENV}"
  echo "ALLURE_REPORT_REASON=Report-generation step did not complete." >> "${GITHUB_ENV}"
fi

report_unavailable() {
  echo "::warning::$1"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "ALLURE_REPORT_REASON=$1" >> "${GITHUB_ENV}"
  fi
}

echo "🔍 Searching for .xcresults under: ${XCRESULT_SEARCH_PATH}"

XCRESULTS=()
while IFS= read -r -d '' xc; do
  XCRESULTS+=("$xc")
done < <(find "${XCRESULT_SEARCH_PATH}" -type d -name "*.xcresult" -print0 2>/dev/null || true)

if [[ "${#XCRESULTS[@]}" -eq 0 ]]; then
  report_unavailable "No xcresult bundles found in the report search directory."
  exit 0
fi

rm -rf allure-reports
mkdir -p allure-reports

XCRESULT="${XCRESULTS[0]}"
if [[ "${#XCRESULTS[@]}" -gt 1 ]]; then
  MERGE_DIR="$(mktemp -d)"
  trap 'rm -rf "$MERGE_DIR"' EXIT
  XCRESULT="$MERGE_DIR/combined.xcresult"
  # Keep the merged bundle outside artifacts so other reporters only see originals.
  if ! xcrun xcresulttool merge --output-path "$XCRESULT" "${XCRESULTS[@]}"; then
    report_unavailable "xcresulttool could not merge the result bundles."
    exit 0
  fi
fi

if ! npx --yes allure awesome "$XCRESULT" --single-file -o allure-reports >/dev/null; then
  report_unavailable "Allure report generation failed. See the report-generation log."
  exit 0
fi

if [[ ! -f allure-reports/index.html ]]; then
  report_unavailable "Allure did not produce allure-reports/index.html."
  exit 0
fi

# The single-file report embeds every screen recording as base64 and can reach several hundred MB, which browsers
# struggle to open. Drop the recordings of attempts that were retried (the latest attempt of each test is kept) and
# re-encode the rest at 540p. The XCResult keeps the originals.
if ! ruby - allure-reports/index.html <<'RUBY'
require "base64"
require "fileutils"
require "json"
require "timeout"
require "tmpdir"

# Allure marks every attempt before the last one of a test with isRetry. Only the attempt's own steps count: its
# "retries" list repeats the recordings of the other attempts.
OWN_CONTENT = %w[steps setup teardown attachments].freeze

def payloads(html, prefix, extension)
    found = []
    position = 0
    while (start = html.index(prefix, position))
        name_end = html.index('","', start)
        from = name_end + 3
        to = html.index('"', from)
        name = html[(start + prefix.size)...name_end]
        found << { name: name, from: from, to: to } if name.end_with?(extension)
        position = to
    end
    found
end

def recording_ids(node, ids = [])
    case node
    when Hash
        ids << node["id"] if node["contentType"] == "video/mp4"
        node.each_value { |child| recording_ids(child, ids) }
    when Array
        node.each { |child| recording_ids(child, ids) }
    end
    ids
end

def without_attachments(node, ids)
    case node
    when Array
        node.reject { |child| child.is_a?(Hash) && ids.include?(child["link"].is_a?(Hash) ? child["link"]["id"] : child["id"]) }
            .map { |child| without_attachments(child, ids) }
    when Hash
        node.transform_values { |child| without_attachments(child, ids) }
    else
        node
    end
end

def shrink(encoded, directory, index)
    source = File.join(directory, "#{index}-in.mp4")
    output = File.join(directory, "#{index}-out.mp4")
    File.binwrite(source, Base64.strict_decode64(encoded))
    pid = Process.spawn("/usr/bin/avconvert", "--source", source, "--output", output, "--preset", "Preset960x540",
                        "--replace", out: File::NULL, err: File::NULL)
    begin
        Timeout.timeout(120) { Process.wait(pid) }
    rescue Timeout::Error
        Process.kill("KILL", pid)
        Process.wait(pid)
        raise "conversion timed out"
    end
    raise "conversion failed" unless $?.success? && File.size?(output) && File.size(output) < File.size(source)

    Base64.strict_encode64(File.binread(output))
rescue StandardError => error
    warn "[report videos] Keeping recording #{index}: #{error.message}"
    encoded
ensure
    FileUtils.rm_f([source, output])
end

path = ARGV.fetch(0)
html = File.binread(path)
videos = payloads(html, 'd("data/attachments/', ".mp4")
exit(0) if videos.empty?

results = payloads(html, 'd("data/test-results/', ".json").map do |entry|
    entry.merge(json: JSON.parse(Base64.strict_decode64(html.byteslice(entry[:from], entry[:to] - entry[:from])).force_encoding("UTF-8")))
end
dropped = results.select { |entry| entry[:json]["isRetry"] }
                 .flat_map { |entry| recording_ids(entry[:json].values_at(*OWN_CONTENT)) }.uniq

started = Time.now
edits = results.filter_map do |entry|
    next unless dropped.any? { |id| entry[:json].to_s.include?(id) }

    entry.slice(:from, :to).merge(value: Base64.strict_encode64(JSON.generate(without_attachments(entry[:json], dropped))))
end

jobs = Queue.new
videos.each { |video| jobs << video }
converted = Queue.new
Dir.mktmpdir("allure-videos-") do |directory|
    Array.new(3) do
        Thread.new do
            while (video = jobs.pop(true) rescue nil)
                value = if dropped.include?(video[:name].delete_suffix(".mp4"))
                    ""
                else
                    shrink(html.byteslice(video[:from], video[:to] - video[:from]), directory, video[:name])
                end
                converted << video.slice(:from, :to).merge(value: value)
            end
        end
    end.each(&:join)
end
edits.concat(Array.new(converted.size) { converted.pop })

File.open("#{path}.tmp", "wb") do |output|
    position = 0
    edits.sort_by { |edit| edit[:from] }.each do |edit|
        output.write(html.byteslice(position, edit[:from] - position))
        output.write(edit[:value])
        position = edit[:to]
    end
    output.write(html.byteslice(position, html.bytesize - position))
end
File.rename("#{path}.tmp", path)
puts "[report videos] #{videos.size} recordings (#{dropped.size} from retried attempts dropped), " \
     "HTML #{html.bytesize / 1048576} -> #{File.size(path) / 1048576} MiB in #{(Time.now - started).round}s"
RUBY
then
  echo "::warning::Video optimization failed. Keeping the original report and recordings."
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "ALLURE_REPORT_AVAILABLE=true" >> "${GITHUB_ENV}"
  echo "ALLURE_REPORT_REASON=" >> "${GITHUB_ENV}"
fi

echo "✅ Allure report generated at ./allure-reports/index.html"
