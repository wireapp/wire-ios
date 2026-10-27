#!/usr/bin/env ruby
# Collect structured warnings from Xcode result bundles and publish a check run.
require 'json'
require 'uri'
require 'net/http'
require 'openssl'
require 'open3'
require 'optparse'
require 'pathname'
require 'set'
require 'fileutils'

module CompilerWarnings
  REPORT = 'build/compiler-warnings.json'.freeze
  RESULT_PATTERN = 'artifacts/**/*.xcresult'.freeze

  def self.git(*arguments)
    output, _error, status = Open3.capture3('git', *arguments)
    raise "Could not run git #{arguments.first}" unless status.success?

    output
  end

  def self.read_build_results(bundle)
    output, error, status = Open3.capture3('xcrun', 'xcresulttool', 'get', 'build-results',
                                         '--schema-version', '0.1.0', '--path', bundle, '--compact')
    raise "xcresulttool exited #{status.exitstatus}: #{error.strip}" unless status.success?

    JSON.parse(output)
  end

  def self.source_location(source_url)
    uri = URI.parse(source_url.to_s)
    return nil unless uri.scheme == 'file' && [nil, '', 'localhost'].include?(uri.host)

    return nil unless uri.path && uri.path.start_with?('/')

    path = URI::DEFAULT_PARSER.unescape(uri.path)
    attributes = URI.decode_www_form(uri.fragment.to_s).to_h
    line = Integer(attributes.fetch('StartingLineNumber'), 10)
    return nil if line.negative?

    # Xcode uses zero-based locations; GitHub uses one-based line numbers.
    [path, line + 1]
  rescue URI::InvalidURIError, ArgumentError, KeyError
    nil
  end

  def self.collect(root:, bundles:, tracked_files:, reader: method(:read_build_results))
    root = File.realpath(root)
    tracked = tracked_files.to_set
    annotations = {}
    untracked = {}
    unlocated = {}
    errors = []
    incomplete = []
    bundles.each do |bundle|
      begin
        results = reader.call(bundle)
        issues = results.fetch('warnings') + results.fetch('analyzerWarnings')
      rescue StandardError => error
        errors << { 'path' => bundle, 'message' => error.message }
        next
      end
      # A failed build can stop before every target is compiled.
      incomplete << "#{bundle} contains build errors; some targets may not have been compiled." unless Array(results['errors']).empty?
      issues.each do |issue|
        message = issue.fetch('message')
        location = source_location(issue['sourceURL'])
        unless location
          # Keep the structured issue, including project/target context. Ignore
          # timestamp fragments when deduplicating warnings without a line.
          source = issue['sourceURL'].to_s.split('#', 2).first
          unlocated[[issue['issueType'], message, source]] = issue
          next
        end
        source, line = location
        absolute = File.expand_path(source, root)
        # Prefer the path as reported so tracked symlinks match; fall back to the
        # resolved path for sources reached through a symlinked directory.
        candidates = [absolute]
        candidates << File.realpath(absolute) if File.exist?(absolute)
        paths = candidates.map { |candidate| Pathname.new(candidate).relative_path_from(Pathname.new(root)).to_s }
        path = paths.find { |candidate| tracked.include?(candidate) } || paths.last
        key = [path, line, message]
        destination = tracked.include?(path) ? annotations : untracked
        destination[key] = {
          'path' => path, 'start_line' => line, 'end_line' => line,
          'annotation_level' => 'warning', 'title' => 'Compiler warning', 'message' => message
        }
      rescue StandardError => error
        # Skip only the malformed issue and keep the rest of the bundle.
        errors << { 'path' => bundle, 'message' => "Skipped an issue: #{error.message}" }
      end
    end
    sort = ->(warnings) { warnings.values.sort_by { |a| [a['path'], a['start_line'], a['message']] } }
    {
      'result_bundles' => bundles, 'result_errors' => errors, 'incomplete_reasons' => incomplete,
      'annotations' => sort.call(annotations), 'untracked_warnings' => sort.call(untracked),
      'unlocated_warnings' => unlocated.values
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
    if report.fetch('result_bundles').empty?
      return 'No .xcresult bundles were found; compiler warnings could not be collected.'
    end
    counts = {
      inline: report.fetch('annotations').length,
      unchanged: report.fetch('unchanged_file_warnings', []).length,
      untracked: report.fetch('untracked_warnings', []).length,
      unlocated: report.fetch('unlocated_warnings').length,
      unmapped: report.fetch('unmapped_warnings', []).length
    }
    text = "Collected #{counts.values.sum} unique compiler warnings: #{counts[:inline]} available inline, " \
           "#{counts[:unchanged]} in files not changed by the PR, #{counts[:untracked]} in untracked files, " \
           "#{counts[:unlocated]} without source locations, " \
           "#{counts[:unmapped]} without matching PR-head source lines. " \
           'The complete report is available in the workflow artifacts.'
    failures = report.fetch('result_errors', []).length
    text += " #{failures} result bundles or issues could not be read; the report is incomplete." if failures.positive?
    report.fetch('incomplete_reasons', []).each { |reason| text += " #{reason}" }
    text
  end

  class API
    class HTTPError < StandardError
      attr_reader :status

      def initialize(status)
        @status = status
        super("GitHub Checks API returned HTTP #{status}")
      end
    end
    RETRYABLE_ERRORS = [HTTPError, Timeout::Error, EOFError, IOError, SocketError, SystemCallError,
                        OpenSSL::SSL::SSLError].freeze

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
    collected = !report.fetch('result_bundles').empty? && report.fetch('result_errors', []).empty? &&
                report.fetch('incomplete_reasons', []).empty?
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
      'status' => 'completed', 'conclusion' => collected ? 'success' : 'neutral', 'output' => output
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

  def self.run(arguments, api: nil, reader: method(:read_build_results))
    options = { publish: false }
    OptionParser.new do |parser|
      parser.banner = 'Usage: ruby scripts/annotate_compiler_warnings.rb [--publish]'
      parser.on('--publish', 'Publish warnings in files changed by the PR using the GitHub Checks API') { options[:publish] = true }
    end.parse!(arguments)
    raise 'Unexpected arguments' unless arguments.empty?

    root = git('rev-parse', '--show-toplevel').strip
    Dir.chdir(root) do
      FileUtils.mkdir_p('build')
      bundles = Dir.glob(RESULT_PATTERN).select { |path| File.directory?(path) }.sort
      report = collect(root: root, bundles: bundles, tracked_files: git('ls-files', '-z').split("\0"), reader: reader)
      report['incomplete_reasons'] << 'The job was cancelled; some targets may not have been compiled.' if ENV['JOB_STATUS'] == 'cancelled'
      report['sha'] = git('rev-parse', 'HEAD').strip
      # Save the collected diagnostics first, even if PR-head mapping or publishing fails.
      File.write(REPORT, JSON.pretty_generate(report) + "\n")
      if options[:publish]
        event = JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH')))
        pull_request = event.fetch('pull_request')
        # Filter before mapping so only the PR's files need per-file git calls.
        changed = pr_changed_files(report.fetch('sha'))
        report = for_changed_files(report, changed || Set.new)
        unless changed
          report['incomplete_reasons'] << 'The build is not a PR merge commit, so the files changed by the PR ' \
                                          'are unknown and no warnings were annotated inline.'
        end
        report = for_pr_head(report, pull_request.fetch('head').fetch('sha'))
        File.write(REPORT, JSON.pretty_generate(report) + "\n")
      end
      puts summary(report)
      if ENV['GITHUB_STEP_SUMMARY']
        File.open(ENV.fetch('GITHUB_STEP_SUMMARY'), 'a') do |file|
          file.puts "### Compiler warnings\n\n#{summary(report)}\n"
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
