#!/usr/bin/env ruby
# frozen_string_literal: true

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

# Syncs the Jira component labels of a PR (or of all open PRs) with the components
# of the Jira ticket referenced in the PR title or branch name.
# Unmapped components (such as "iOS") are ignored.
#
# PR selection: PR_NUMBER if set, otherwise the PR of the `pull_request` event
# (GITHUB_EVENT_PATH), otherwise every open PR.
#
# Required env: GITHUB_TOKEN, JIRA_TOKEN, GITHUB_REPOSITORY.
# Optional env: PR_NUMBER, GITHUB_EVENT_NAME, GITHUB_EVENT_PATH.

require 'base64'
require 'json'
require 'net/http'
require 'uri'

JIRA_BASE_URL = 'https://wearezeta.atlassian.net'
LABEL_COLOR = 'C5DEF5'

# Jira component name => GitHub label name. Components not listed here (e.g. "iOS") are ignored.
LABEL_BY_COMPONENT = {
  'Discipline' => 'Discipline',
  'Calling' => 'Calling',
  'Messenger' => 'Messenger',
  'Core' => 'Core',
  'Files' => 'Files',
  'Administration & Identity' => 'Administration & Identity'
}.freeze
MANAGED_LABELS = LABEL_BY_COMPONENT.values.uniq.freeze

GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN')
REPO = ENV.fetch('GITHUB_REPOSITORY')
JIRA_AUTH = "Basic #{Base64.strict_encode64(ENV.fetch('JIRA_TOKEN'))}"

def request(method, url, headers: {}, body: nil)
  uri = URI(url)
  req = Net::HTTPGenericRequest.new(method, !body.nil?, true, uri.request_uri, headers)
  req.body = JSON.generate(body) if body
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
end

def github(method, path, body: nil)
  url = path.start_with?('http') ? path : "https://api.github.com/repos/#{REPO}#{path}"
  request(
    method, url,
    headers: {
      'Authorization' => "Bearer #{GITHUB_TOKEN}",
      'Accept' => 'application/vnd.github+json',
      'Content-Type' => 'application/json',
      'X-GitHub-Api-Version' => '2022-11-28'
    },
    body: body
  )
end

# GET that follows `Link: rel="next"` pagination.
def github_paginate(path)
  results = []
  url = "#{path}#{path.include?('?') ? '&' : '?'}per_page=100"
  while url
    res = github('GET', url)
    abort "GitHub GET #{url}: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
    results.concat(JSON.parse(res.body))
    url = res['Link'].to_s[/<([^>]+)>;\s*rel="next"/, 1]
  end
  results
end

def jira_components(key)
  res = request(
    'GET', "#{JIRA_BASE_URL}/rest/api/3/issue/#{key}?fields=components",
    headers: { 'Authorization' => JIRA_AUTH, 'Accept' => 'application/json' }
  )
  raise "Jira #{key}: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

  JSON.parse(res.body).dig('fields', 'components').to_a.map { |c| c['name'] }
end

# Creates any missing component label once per run.
def ensure_labels
  existing = github_paginate('/labels').map { |l| l['name'] }
  (MANAGED_LABELS - existing).each do |name|
    res = github('POST', '/labels', body: { name: name, color: LABEL_COLOR, description: 'Jira component' })
    # 422 means another run created it first.
    raise "Create label #{name}: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess) || res.code == '422'

    puts "Created label \"#{name}\""
  end
end

def sync_pr(number)
  # Re-read the PR: the webhook payload is an event-time snapshot of title and labels.
  res = github('GET', "/pulls/#{number}")
  raise "PR ##{number}: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

  pr = JSON.parse(res.body)
  if pr.dig('head', 'repo', 'full_name') != pr.dig('base', 'repo', 'full_name')
    puts "::notice::PR ##{number}: fork PR, skipped"
    return
  end

  ticket = pr['title'][/\bWPB-\d+\b/] || pr.dig('head', 'ref')[/WPB-\d+/i]&.upcase
  unless ticket
    puts "::notice::PR ##{number}: no WPB ticket in title or branch, skipped"
    return
  end

  desired = jira_components(ticket).filter_map { |c| LABEL_BY_COMPONENT[c] }.uniq
  puts "::warning::PR ##{number} (#{ticket}): no mapped component on the ticket" if desired.empty?

  current = pr['labels'].map { |l| l['name'] } & MANAGED_LABELS
  to_add = desired - current
  to_remove = current - desired

  unless to_add.empty?
    res = github('POST', "/issues/#{number}/labels", body: { labels: to_add })
    raise "PR ##{number} add labels: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
  end
  to_remove.each do |name|
    res = github('DELETE', "/issues/#{number}/labels/#{URI.encode_www_form_component(name).gsub('+', '%20')}")
    raise "PR ##{number} remove label #{name}: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)
  end
  puts "PR ##{number} (#{ticket}): added [#{to_add.join(', ')}] removed [#{to_remove.join(', ')}]"
end

ensure_labels

requested = ENV.fetch('PR_NUMBER', '').strip
if !requested.empty?
  sync_pr(requested.to_i)
elsif ENV['GITHUB_EVENT_NAME'] == 'pull_request'
  sync_pr(JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH'))).dig('pull_request', 'number'))
else
  failures = []
  github_paginate('/pulls?state=open').each do |pr|
    sync_pr(pr['number'])
  rescue StandardError => e
    puts "::error::PR ##{pr['number']}: #{e.message}"
    failures << pr['number']
  end
  abort "Failed to sync PRs: #{failures.join(', ')}" unless failures.empty?
end
