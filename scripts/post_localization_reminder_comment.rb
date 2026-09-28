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
#

# Creates, updates, or removes the "new localization strings" PR comment.
#
# Required env: GITHUB_TOKEN, GITHUB_REPOSITORY, PR_NUMBER, HAS_NEW_STRINGS,
# NEW_KEYS (only read when HAS_NEW_STRINGS is "true").

require 'json'
require 'net/http'
require 'uri'

MARKER = '<!-- localization-reminder -->'

token = ENV.fetch('GITHUB_TOKEN')
repo = ENV.fetch('GITHUB_REPOSITORY')
pr_number = ENV.fetch('PR_NUMBER')
has_new_strings = ENV.fetch('HAS_NEW_STRINGS') == 'true'

def api_request(method, path, token, body: nil)
  uri = URI("https://api.github.com#{path}")
  request = method.new(uri)
  request['Authorization'] = "Bearer #{token}"
  request['Accept'] = 'application/vnd.github+json'
  request['X-GitHub-Api-Version'] = '2022-11-28'
  request.body = JSON.generate(body) if body

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
  raise "#{method::METHOD} #{path} failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

  response.body && !response.body.empty? ? JSON.parse(response.body) : nil
end

def find_marker_comment(repo, pr_number, token)
  page = 1
  loop do
    comments = api_request(Net::HTTP::Get, "/repos/#{repo}/issues/#{pr_number}/comments?per_page=100&page=#{page}", token)
    break nil if comments.empty?

    found = comments.find { |c| c['body'].include?(MARKER) }
    return found if found
    return nil if comments.size < 100

    page += 1
  end
end

existing = find_marker_comment(repo, pr_number, token)

unless has_new_strings
  # A follow-up push may have removed the strings that triggered the original
  # reminder - drop the now-stale comment.
  api_request(Net::HTTP::Delete, "/repos/#{repo}/issues/comments/#{existing['id']}", token) if existing
  exit
end

keys = ENV.fetch('NEW_KEYS').split("\n").reject(&:empty?)
bullet_list = keys.map { |k| "- #{k}" }.join("\n")
body = [
  MARKER,
  'Please make sure new localizations are translated once merged to develop.',
  'We need 100% German translations before releasing.',
  '',
  '**New strings (English):**',
  bullet_list,
].join("\n")

if existing
  api_request(Net::HTTP::Patch, "/repos/#{repo}/issues/comments/#{existing['id']}", token, body: { body: body })
else
  api_request(Net::HTTP::Post, "/repos/#{repo}/issues/#{pr_number}/comments", token, body: { body: body })
end
