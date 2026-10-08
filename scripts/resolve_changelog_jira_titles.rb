require 'base64'
require 'json'
require 'net/http'
require 'uri'

path = 'CHANGELOG.md'
base = ENV.fetch('JIRA_BASE_URL')
token = ENV['JIRA_TOKEN']

warn '::warning::JIRA_TOKEN not set - keeping commit titles' unless token

auth = token ? "Basic #{Base64.strict_encode64(token)}" : nil
cache = {}

def title_for(key, base, auth, cache)
  return cache[key] if cache.key?(key)

  summary = nil
  if auth
    uri = URI("#{base}/rest/api/3/issue/#{key}?fields=summary")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = auth
    request['Accept'] = 'application/json'

    begin
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        json = JSON.parse(response.body)
        summary = json.dig('fields', 'summary')
        # Tickets are often prefixed with a platform tag like "[iOS] " - drop it.
        summary = summary.sub(/^\s*\[[^\]]*\]\s*/, '') if summary
      else
        warn "::warning::Jira #{key}: #{response.code} #{response.body}"
      end
    rescue StandardError => e
      warn "::warning::Jira #{key}: #{e.message}"
    end
  end

  cache[key] = summary
end

# Trailing commit-sha link that generate-changelog appends, e.g. " [abc1234](url)".
link_tail = /\s*\[[0-9a-f]{6,}\]\([^)]+\)\s*$/i
lines = File.read(path).split("\n", -1)
out = []

lines.each do |line|
  key_match = line.match(/WPB-\d+/i)
  unless line.start_with?('*') && key_match
    # Drop any link from non-ticket bullets too - the changelog carries no links.
    out << line.sub(link_tail, '')
    next
  end

  key = key_match[0].upcase
  summary = title_for(key, base, auth, cache)

  if summary
    # "<title> - WPB-XXX", no links.
    out << "* #{summary} - #{key}"
  else
    out << line.sub(link_tail, '')
  end
end

File.write(path, out.join("\n"))
puts "Resolved #{cache.size} JIRA ticket(s) in the changelog."
