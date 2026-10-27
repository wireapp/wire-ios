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
    output, _error, status = Open3.capture3('git', *arguments)
    raise "Could not run git #{arguments.first}" unless status.success?

    output
  end

  def self.collect(root:, logs:, tracked_files:)
    root = File.realpath(root)
    tracked = tracked_files.to_set
    annotations = {}
    untracked = {}
    unlocated = Set.new
    logs.each do |log|
      File.foreach(log, encoding: 'UTF-8') do |raw|
        line = raw.scrub.gsub(/\e\[[0-9;]*m/, '').strip
        match = line.match(/\A(.+?):(\d+):(?:(\d+):)?\s+warning:\s*(.+)\z/)
        unless match
          # Keep tool and project prefixes so their context survives in the report.
          unlocated.add(line.sub(/\Awarning:\s*/, '')) if line.match?(/\bwarning:/)
          next
        end

        source, number, _column, message = match.captures
        unless number.to_i.positive?
          unlocated.add(line)
          next
        end
        message = message.sub(/ \(in target '.+' from project '.+'\)\z/, '')
        absolute = File.expand_path(source, root)
        absolute = File.realpath(absolute) if File.exist?(absolute)
        path = Pathname.new(absolute).relative_path_from(Pathname.new(root)).to_s
        # Annotations are line-based, so columns must not create identical entries.
        key = [path, number.to_i, message]
        destination = tracked.include?(path) ? annotations : untracked
        destination[key] = {
          'path' => path, 'start_line' => number.to_i, 'end_line' => number.to_i,
          'annotation_level' => 'warning', 'title' => 'Compiler warning', 'message' => message
        }
      end
    end
    sort = ->(warnings) { warnings.values.sort_by { |a| [a['path'], a['start_line'], a['message']] } }
    {
      'logs' => logs, 'annotations' => sort.call(annotations),
      'untracked_warnings' => sort.call(untracked), 'unlocated_warnings' => unlocated.to_a.sort
    }
  end

  def self.head_line(line, hunks)
    offset = 0
    hunks.each do |old_start, old_count, new_start, new_count|
      # A zero-length new range denotes lines deleted from the built tree, after
      # new_start. That line itself still maps using the preceding offset.
      break if line < new_start || (new_count.zero? && line <= new_start)
      return nil if new_count.positive? && line < new_start + new_count

      offset += old_count - new_count
    end
    line + offset
  end

  def self.for_pr_head(report, head_sha)
    built_sha = report.fetch('sha')
    changed = git('diff', '--no-renames', '--name-only', '-z', head_sha, built_sha).split("\0").to_set
    annotations = []
    unmapped = []
    report.fetch('annotations').group_by { |warning| warning.fetch('path') }.each do |path, warnings|
      unless changed.include?(path)
        annotations.concat(warnings)
        next
      end
      exists = git('ls-tree', '-z', head_sha, '--', path).match?(/\A\d+ blob /)
      diff = git('diff', '--no-ext-diff', '--no-textconv', '--no-color', '--no-renames',
                 '--unified=0', head_sha, built_sha, '--', path)
      hunks = diff.scan(/^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/).map do |old_start, old_count, new_start, new_count|
        [old_start.to_i, (old_count || '1').to_i, new_start.to_i, (new_count || '1').to_i]
      end
      warnings.each do |warning|
        line = exists ? head_line(warning.fetch('start_line'), hunks) : nil
        if line
          annotations << warning.merge('start_line' => line, 'end_line' => line)
        else
          unmapped << warning.merge('reason' => 'Source line is absent or changed in the PR head.')
        end
      end
    end
    # Preserve every original diagnostic, including warnings that have no safe
    # location in the PR head. Only the mapped annotations are sent to GitHub.
    report.merge('head_sha' => head_sha, 'build_annotations' => report.fetch('annotations'),
                 'annotations' => annotations, 'unmapped_warnings' => unmapped)
  end

  # PR jobs build a merge commit whose first parent is the base branch, so the
  # diff against that parent lists exactly the files changed by the PR.
  def self.pr_changed_files(built_sha)
    parents = git('rev-list', '--parents', '-n', '1', built_sha).split.drop(1)
    return nil unless parents.length == 2

    git('diff', '--no-renames', '--name-only', '-z', parents.first, built_sha).split("\0").to_set
  end

  def self.for_changed_files(report, changed)
    # Reviewers only see annotations on diff lines, so warnings in other files
    # stay in the report instead of being uploaded.
    inside, outside = report.fetch('annotations').partition { |warning| changed.include?(warning.fetch('path')) }
    report.merge('annotations' => inside, 'unchanged_file_warnings' => outside)
  end

  def self.summary(report)
    counts = {
      inline: report.fetch('annotations').length,
      unchanged: report.fetch('unchanged_file_warnings', []).length,
      untracked: report.fetch('untracked_warnings', []).length,
      unlocated: report.fetch('unlocated_warnings').length,
      unmapped: report.fetch('unmapped_warnings', []).length
    }
    "Collected #{counts.values.sum} unique compiler warnings: #{counts[:inline]} available inline, " \
      "#{counts[:unchanged]} in files not changed by the PR, #{counts[:untracked]} in untracked files, " \
      "#{counts[:unlocated]} without source locations, " \
      "#{counts[:unmapped]} without matching PR-head source lines. " \
      'The complete report is available in the workflow artifacts.'
  end

  class API
    class HTTPError < StandardError
      attr_reader :status

      def initialize(status)
        @status = status
        super("GitHub Checks API returned HTTP #{status}")
      end
    end
    RETRYABLE_ERRORS = [HTTPError, Timeout::Error, EOFError, IOError, SocketError, SystemCallError].freeze

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
      attempts = 0
      begin
        attempts += 1
        response = perform(uri, request)
        raise HTTPError, response.code.to_i unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue *RETRYABLE_ERRORS => error
        # Creating a check and appending annotations are not idempotent. A lost
        # response can mean GitHub already accepted them; replay would duplicate
        # checks or warnings. Only retry updates that replace check metadata.
        safe = method == :patch && !body.fetch('output', {}).key?('annotations')
        transient = !error.is_a?(HTTPError) || error.status.between?(500, 599)
        raise unless safe && transient && attempts < 3

        sleep(2**(attempts - 1))
        retry
      end
    end

    def perform(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                      open_timeout: 15, read_timeout: 60) do |http|
        http.max_retries = 0
        http.request(request)
      end
    end
  end

  def self.publish(api:, repository:, sha:, name:, report:, details_url:)
    completed = false
    output = { 'title' => name, 'summary' => summary(report) }
    if report.fetch('logs').empty?
      output['summary'] = 'No build logs from this run were found; compiler warnings could not be collected.'
    end
    # Start neutral and completed: even SIGKILL or a lost POST response cannot
    # leave a blocking check stuck in progress. Success is set after all batches.
    check = api.request(:post, "/repos/#{repository}/check-runs", {
      'name' => name, 'head_sha' => sha, 'status' => 'completed', 'conclusion' => 'neutral',
      'details_url' => details_url,
      'output' => output.merge('summary' => "Warning publication has not completed. #{output.fetch('summary')}")
    })
    endpoint = "/repos/#{repository}/check-runs/#{check.fetch('id')}"
    report.fetch('annotations').each_slice(50) do |batch|
      api.request(:patch, endpoint, { 'output' => output.merge('annotations' => batch) })
    end
    api.request(:patch, endpoint, {
      'status' => 'completed', 'conclusion' => report.fetch('logs').empty? ? 'neutral' : 'success', 'output' => output
    })
    completed = true
  ensure
    # Also runs for Interrupt and SignalException, without swallowing the signal.
    if endpoint && !completed
      begin
        api.request(:patch, endpoint, {
          'status' => 'completed', 'conclusion' => 'neutral',
          'output' => { 'title' => name, 'summary' => 'Publishing compiler warnings was interrupted. ' \
                       'Annotations may be incomplete; see the full report in the workflow artifacts.' }
        })
      rescue StandardError
        # The initial neutral state remains safe if cleanup cannot reach GitHub.
      end
    end
  end

  def self.run(arguments, api: nil)
    options = { publish: false }
    OptionParser.new do |parser|
      parser.banner = 'Usage: ruby scripts/annotate_compiler_warnings.rb [--publish]'
      parser.on('--publish', 'Publish warnings in files changed by the PR using the GitHub Checks API') { options[:publish] = true }
    end.parse!(arguments)
    raise 'Unexpected arguments' unless arguments.empty?

    root = git('rev-parse', '--show-toplevel').strip
    Dir.chdir(root) do
      FileUtils.mkdir_p('build')
      logs = LOG_PATTERNS.flat_map { |pattern| Dir.glob(pattern) }.sort
      report = collect(root: root, logs: logs, tracked_files: git('ls-files', '-z').split("\0"))
      report['sha'] = git('rev-parse', 'HEAD').strip
      # Save the raw report first, even if PR-head mapping or publishing fails.
      File.write(REPORT, JSON.pretty_generate(report) + "\n")
      if options[:publish]
        event = JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH')))
        pull_request = event.fetch('pull_request')
        report = for_pr_head(report, pull_request.fetch('head').fetch('sha'))
        changed = pr_changed_files(report.fetch('sha'))
        report = for_changed_files(report, changed) if changed
        File.write(REPORT, JSON.pretty_generate(report) + "\n")
      end
      puts summary(report)
      if ENV['GITHUB_STEP_SUMMARY']
        File.open(ENV.fetch('GITHUB_STEP_SUMMARY'), 'a') do |file|
          file.puts "### Compiler warnings\n\n#{summary(report)}\n"
          file.puts "\nNo build logs were found; this does not indicate a warning-free build." if logs.empty?
        end
      end
      return unless options[:publish]

      if pull_request.dig('head', 'repo', 'full_name') != ENV.fetch('GITHUB_REPOSITORY')
        puts 'Fork PR: report saved as an artifact; check publishing requires a writable token.'
        return
      end
      api ||= API.new(token: ENV.fetch('GH_TOKEN'), base_url: ENV.fetch('GITHUB_API_URL', 'https://api.github.com'))
      repository = ENV.fetch('GITHUB_REPOSITORY')
      details_url = "#{ENV.fetch('GITHUB_SERVER_URL', 'https://github.com')}/#{repository}/actions/runs/#{ENV.fetch('GITHUB_RUN_ID')}"
      publish(api: api, repository: repository, sha: report.fetch('head_sha'),
              name: ENV.fetch('COMPILER_WARNINGS_CHECK_NAME', 'Compiler warnings'), report: report, details_url: details_url)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    CompilerWarnings.run(ARGV)
  rescue StandardError => error
    warn "Compiler warning reporting failed: #{error.class}: #{error.message}"
    exit 1
  end
end
