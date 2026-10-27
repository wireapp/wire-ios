#!/usr/bin/env ruby
# Collect compiler warnings from Fastlane's raw build logs and publish a check run.
require 'json'
require 'net/http'
require 'open3'
require 'optparse'
require 'pathname'
require 'set'
require 'fileutils'

module CompilerWarnings
  REPORT = 'build/compiler-warnings.json'.freeze
  LOG_PATTERNS = ['build/*.log', 'fastlane/build/*.log'].freeze

  def self.git(*arguments)
    output, status = Open3.capture2('git', *arguments)
    raise 'Could not read the checked-out Git revision' unless status.success?

    output
  end

  def self.collect(root:, logs:, tracked_files:)
    root = File.realpath(root)
    tracked = tracked_files.to_set
    annotations = {}
    unlocated = Set.new
    logs.each do |log|
      File.foreach(log, encoding: 'UTF-8', invalid: :replace, undef: :replace) do |raw|
        line = raw.gsub(/\e\[[0-9;]*m/, '').strip
        match = line.match(/\A(.+?):(\d+):(?:(\d+):)?\s+warning:\s*(.+)\z/)
        unless match
          unlocated.add(line.sub(/\Awarning:\s*/, '')) if line.start_with?('warning:')
          next
        end

        source, number, column, message = match.captures
        message = message.sub(/ \(in target '.+' from project '.+'\)\z/, '')
        absolute = File.expand_path(source, root)
        absolute = File.realpath(absolute) if File.exist?(absolute)
        path = Pathname.new(absolute).relative_path_from(Pathname.new(root)).to_s
        next unless tracked.include?(path) && number.to_i.positive?

        # Columns help distinguish diagnostics on the same line, but are omitted
        # from annotations because some compiler diagnostics report column zero.
        key = [path, number.to_i, column.to_i, message]
        annotations[key] = {
          'path' => path, 'start_line' => number.to_i, 'end_line' => number.to_i,
          'annotation_level' => 'warning', 'title' => 'Compiler warning', 'message' => message
        }
      end
    end
    {
      'logs' => logs, 'annotations' => annotations.values.sort_by { |a| [a['path'], a['start_line'], a['message']] },
      'unlocated_warnings' => unlocated.to_a.sort
    }
  end

  class API
    def initialize(token:, base_url:)
      @token = token
      @base_url = base_url
    end

    def request(method, path, body)
      uri = URI("#{@base_url}#{path}")
      request = (method == :post ? Net::HTTP::Post : Net::HTTP::Patch).new(uri)
      request['Authorization'] = "Bearer #{@token}"
      request['Accept'] = 'application/vnd.github+json'
      request['Content-Type'] = 'application/json'
      request['X-GitHub-Api-Version'] = '2022-11-28'
      request.body = JSON.generate(body)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                 open_timeout: 15, read_timeout: 60) { |http| http.request(request) }
      raise "GitHub Checks API returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end

  def self.publish(api:, repository:, sha:, name:, report:, details_url:)
    summary = "#{report.fetch('annotations').length} unique compiler warnings in repository files. " \
              "#{report.fetch('unlocated_warnings').length} warnings without source locations. " \
              'The complete report is available in the workflow artifacts.'
    if report.fetch('logs').empty?
      summary = 'No build logs from this run were found; compiler warnings could not be collected.'
    end
    output = { 'title' => name, 'summary' => summary }
    check = api.request(:post, "/repos/#{repository}/check-runs", {
      'name' => name, 'head_sha' => sha, 'status' => 'in_progress',
      'details_url' => details_url, 'output' => output
    })
    endpoint = "/repos/#{repository}/check-runs/#{check.fetch('id')}"
    # The Checks API accepts 50 annotations per request. Updating appends them.
    report.fetch('annotations').each_slice(50) do |batch|
      api.request(:patch, endpoint, { 'output' => output.merge('annotations' => batch) })
    end
    api.request(:patch, endpoint, {
      'status' => 'completed', 'conclusion' => report.fetch('logs').empty? ? 'neutral' : 'success'
    })
  rescue StandardError
    if endpoint
      begin
        api.request(:patch, endpoint, {
          'status' => 'completed', 'conclusion' => 'neutral',
          'output' => { 'title' => name, 'summary' => 'Publishing compiler warnings was interrupted. ' \
                       'Annotations may be incomplete; see the full report in the workflow artifacts.' }
        })
      rescue StandardError
        # Preserve the original failure if GitHub is also unavailable for cleanup.
      end
    end
    raise
  end

  def self.run(arguments, api: nil)
    options = { publish: false }
    OptionParser.new do |parser|
      parser.banner = 'Usage: ruby scripts/annotate_compiler_warnings.rb [--publish]'
      parser.on('--publish', 'Publish all repository warnings using the GitHub Checks API') { options[:publish] = true }
    end.parse!(arguments)
    raise 'Unexpected arguments' unless arguments.empty?

    root = git('rev-parse', '--show-toplevel').strip
    Dir.chdir(root) do
      FileUtils.mkdir_p('build')
      # CI starts with checkout's default cleanup, so the build directories only
      # contain logs produced by this job. No separate start marker is needed.
      logs = LOG_PATTERNS.flat_map { |pattern| Dir.glob(pattern) }.sort
      report = collect(root: root, logs: logs, tracked_files: git('ls-files', '-z').split("\0"))
      # Keep the built revision in the report for troubleshooting. PR jobs build
      # a temporary merge commit, which cannot associate a custom check with a PR.
      report['sha'] = git('rev-parse', 'HEAD').strip
      File.write(REPORT, JSON.pretty_generate(report) + "\n")
      puts "Collected #{report.fetch('annotations').length} unique compiler warnings from #{logs.length} build logs."
      if ENV['GITHUB_STEP_SUMMARY']
        File.open(ENV.fetch('GITHUB_STEP_SUMMARY'), 'a') do |file|
          file.puts "### Compiler warnings\n\n#{report.fetch('annotations').length} unique warnings in repository files " \
                    "from #{logs.length} current build logs. Full report: `#{REPORT}` in workflow artifacts.\n"
          file.puts "\nNo build logs were found; this does not indicate a warning-free build." if logs.empty?
        end
      end
      return unless options[:publish]

      event = JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH')))
      pull_request = event.fetch('pull_request')
      if pull_request.dig('head', 'repo', 'full_name') != ENV.fetch('GITHUB_REPOSITORY')
        puts 'Fork PR: report saved as an artifact; check publishing requires a writable token.'
        return
      end
      api ||= API.new(token: ENV.fetch('GH_TOKEN'), base_url: ENV.fetch('GITHUB_API_URL', 'https://api.github.com'))
      repository = ENV.fetch('GITHUB_REPOSITORY')
      details_url = "#{ENV.fetch('GITHUB_SERVER_URL', 'https://github.com')}/#{repository}/actions/runs/#{ENV.fetch('GITHUB_RUN_ID')}"
      # Use the head from the original event, not a live PR lookup: a newer push
      # may arrive while this build is running.
      publish(api: api, repository: repository, sha: pull_request.fetch('head').fetch('sha'),
              name: ENV.fetch('COMPILER_WARNINGS_CHECK_NAME', 'Compiler warnings'), report: report, details_url: details_url)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    CompilerWarnings.run(ARGV)
  rescue StandardError => error
    # Do not print API response bodies or compiler text as workflow commands.
    warn "Compiler warning reporting failed: #{error.class}: #{error.message}"
    exit 1
  end
end
