require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../annotate_compiler_warnings'

class CompilerWarningsTest < Minitest::Test
  class FakeAPI
    attr_reader :requests

    def initialize
      @requests = []
    end

    def request(method, path, body)
      @requests << [method, path, body]
      { 'id' => 123 }
    end
  end

  def setup
    @environment = ENV.to_h
    ENV.delete('GITHUB_STEP_SUMMARY')
    @root = File.realpath(Dir.mktmpdir('compiler-warnings'))
    @source = 'Sources/Some File.swift'
    @log = File.join(@root, 'build.log')
  end

  def teardown
    FileUtils.remove_entry(@root)
    ENV.replace(@environment)
  end

  def collect(lines, tracked = [@source])
    File.write(@log, lines.join("\n") + "\n")
    CompilerWarnings.collect(root: @root, logs: [@log], tracked_files: tracked)
  end

  def diagnostic(line: 42, column: 7, message: 'Deprecated API', path: File.join(@root, @source))
    "#{path}:#{line}:#{column}: warning: #{message}"
  end

  def publish(report)
    @api = FakeAPI.new
    CompilerWarnings.publish(api: @api, repository: 'wireapp/wire-ios', sha: 'built-sha',
                             name: 'Compiler warnings', report: report, details_url: 'https://example.com/run')
  end

  def test_parses_absolute_paths_with_spaces_and_ansi_colors
    report = collect(["\e[33m#{diagnostic}\e[0m"])
    assert_equal [{ 'path' => @source, 'start_line' => 42, 'end_line' => 42,
                    'annotation_level' => 'warning', 'title' => 'Compiler warning', 'message' => 'Deprecated API' }],
                 report.fetch('annotations')
  end

  def test_resolves_source_paths_through_macos_workspace_symlinks
    FileUtils.mkdir_p(File.join(@root, 'Sources'))
    File.write(File.join(@root, @source), '// fixture')
    File.symlink(@root, File.join(@root, 'alias'))
    report = collect([diagnostic(path: File.join(@root, 'alias', @source))])
    assert_equal [@source], report.fetch('annotations').map { |annotation| annotation.fetch('path') }
  end

  def test_parses_relative_paths_and_diagnostics_without_columns
    report = collect(["#{@source}:12: warning: Unused value"])
    assert_equal 12, report.fetch('annotations').first.fetch('start_line')
  end

  def test_deduplicates_warnings_across_logs_and_preserves_distinct_messages
    collect([diagnostic, diagnostic, diagnostic(message: 'Unused value')])
    report = CompilerWarnings.collect(root: @root, logs: [@log, @log], tracked_files: [@source])
    assert_equal 2, report.fetch('annotations').length
  end

  def test_records_dependencies_generated_files_and_paths_outside_repository_without_annotating_them
    report = collect([
      diagnostic(path: 'DerivedData/CachedSwiftPackages/Dependency.swift'),
      diagnostic(path: File.join(@root, '..', 'External.swift')),
      diagnostic(path: 'Sources/../Untracked.swift'),
      diagnostic(path: @source)
    ])
    assert_equal [@source], report.fetch('annotations').map { |annotation| annotation.fetch('path') }
    assert_equal 3, report.fetch('untracked_warnings').length
    assert_match(/Collected 4 unique compiler warnings/, CompilerWarnings.summary(report))
  end

  def test_deduplicates_the_same_warning_across_target_suffixes
    report = collect([diagnostic + " (in target 'App' from project 'Wire')",
                      diagnostic + " (in target 'Tests' from project 'Wire')"])
    assert_equal 1, report.fetch('annotations').length
    assert_equal 'Deprecated API', report.fetch('annotations').first.fetch('message')
  end

  def test_keeps_warning_text_that_looks_like_a_workflow_command_as_data
    report = collect([diagnostic(message: '::error::Not a workflow command')])
    publish(report)
    batch = @api.requests[1][2].fetch('output').fetch('annotations')
    assert_equal '::error::Not a workflow command', batch.first.fetch('message')
  end

  def test_failed_annotation_upload_attempts_to_complete_the_check_and_propagates_the_error
    api = FakeAPI.new
    def api.request(method, path, body)
      @requests << [method, path, body]
      raise 'Upload failed' if body.dig('output', 'annotations')

      { 'id' => 123 }
    end
    error = assert_raises(RuntimeError) do
      CompilerWarnings.publish(api: api, repository: 'wireapp/wire-ios', sha: 'built-sha',
                               name: 'Compiler warnings', report: collect([diagnostic]), details_url: 'https://example.com')
    end
    assert_equal 'Upload failed', error.message
    assert_equal 'completed', api.requests.last[2].fetch('status')
    assert_equal 'neutral', api.requests.last[2].fetch('conclusion')
  end

  def test_preserves_distinct_warnings_on_the_same_line
    report = collect([diagnostic(message: 'First'), diagnostic(message: 'Second')])
    assert_equal %w[First Second], report.fetch('annotations').map { |annotation| annotation.fetch('message') }
  end

  def test_ignores_errors_notes_and_invalid_lines_and_records_unlocated_warnings
    report = collect(['warning: Linker warning', 'warning: Linker warning',
                      diagnostic(line: 0), diagnostic.sub('warning:', 'error:'), 'note: More information'])
    assert_empty report.fetch('annotations')
    assert_includes report.fetch('unlocated_warnings'), 'Linker warning'
    assert_equal 2, report.fetch('unlocated_warnings').length
  end

  def test_publishes_hundreds_of_warnings_without_truncation_in_batches_of_50
    report = collect((1..327).map { |line| diagnostic(line: line) })
    publish(report)
    batches = @api.requests.select { |request| request[2].dig('output', 'annotations') }
    assert_equal [50, 50, 50, 50, 50, 50, 27], batches.map { |request| request[2]['output']['annotations'].length }
    assert_equal report.fetch('annotations'), batches.flat_map { |request| request[2]['output']['annotations'] }
    assert_equal 'built-sha', @api.requests.first[2].fetch('head_sha')
    assert_equal 'completed', @api.requests.last[2].fetch('status')
    assert_equal 'success', @api.requests.last[2].fetch('conclusion')
  end

  def test_creates_a_successful_check_without_annotations_when_logs_have_no_warnings
    publish(collect(['Build succeeded']))
    assert_equal 2, @api.requests.length
    assert_equal 'success', @api.requests.last[2].fetch('conclusion')
  end

  def test_missing_logs_are_reported_as_unavailable_rather_than_warning_free
    publish({ 'annotations' => [], 'logs' => [], 'unlocated_warnings' => [] })
    assert_equal 'neutral', @api.requests.last[2].fetch('conclusion')
    assert_match(/could not be collected/, @api.requests.first[2].fetch('output').fetch('summary'))
  end

  def in_repository
    assert system('git', 'init', '-q', @root)
    Dir.chdir(@root) do
      FileUtils.mkdir_p('Sources')
      File.write(@source, '// fixture')
      assert system('git', 'add', @source)
      assert system('git', '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
                    '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                    'commit', '-qm', 'Fixture')
      yield
    end
  end

  def test_cli_discovers_build_logs_and_saves_the_full_report
    in_repository do
      FileUtils.mkdir_p('build')
      FileUtils.mkdir_p('fastlane/build')
      File.write('build/current.log', (1..327).map { |line| diagnostic(line: line) }.join("\n"))
      File.write('fastlane/build/second.log', diagnostic)
      File.write('unrelated.log', diagnostic(message: 'Not a build log'))
      CompilerWarnings.run([])
      report = JSON.parse(File.read(CompilerWarnings::REPORT))
      assert_equal ['build/current.log', 'fastlane/build/second.log'], report.fetch('logs')
      assert_equal 327, report.fetch('annotations').length
      assert_equal CompilerWarnings.git('rev-parse', 'HEAD').strip, report.fetch('sha')
    end
  end

  def test_cli_handles_missing_logs_without_preparation
    in_repository do
      CompilerWarnings.run([])
      report = JSON.parse(File.read(CompilerWarnings::REPORT))
      assert_empty report.fetch('logs')
      assert_empty report.fetch('annotations')
    end
  end

  def test_cli_attaches_the_check_to_the_event_pr_head_instead_of_the_built_merge_commit
    in_repository do
      pr_head = CompilerWarnings.git('rev-parse', 'HEAD').strip
      assert system('git', '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
                    '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                    'commit', '--allow-empty', '-qm', 'Simulated merge revision')
      built_sha = CompilerWarnings.git('rev-parse', 'HEAD').strip
      refute_equal pr_head, built_sha
      FileUtils.mkdir_p('build')
      File.write('build/current.log', diagnostic)
      event_path = File.join(@root, 'event.json')
      File.write(event_path, JSON.generate('pull_request' => {
        'head' => { 'sha' => pr_head, 'repo' => { 'full_name' => 'wireapp/wire-ios' } }
      }))
      ENV['GITHUB_EVENT_PATH'] = event_path
      ENV['GITHUB_REPOSITORY'] = 'wireapp/wire-ios'
      ENV['GITHUB_RUN_ID'] = '123'
      ENV['GITHUB_SHA'] = built_sha
      api = FakeAPI.new
      CompilerWarnings.run(['--publish'], api: api)
      assert_equal pr_head, api.requests.first[2].fetch('head_sha')
      report = JSON.parse(File.read(CompilerWarnings::REPORT))
      assert_equal built_sha, report.fetch('sha')
      assert_equal 1, api.requests[1][2].fetch('output').fetch('annotations').length
    end
  end

  def test_full_report_survives_publishing_failure
    in_repository do
      FileUtils.mkdir_p('build')
      File.write('build/current.log', diagnostic)
      event_path = File.join(@root, 'event.json')
      File.write(event_path, JSON.generate('pull_request' => { 'head' => { 'sha' => CompilerWarnings.git('rev-parse', 'HEAD').strip, 'repo' => { 'full_name' => 'wireapp/wire-ios' } } }))
      previous = ENV.to_h
      begin
        ENV['GITHUB_EVENT_PATH'] = event_path
        ENV['GITHUB_REPOSITORY'] = 'wireapp/wire-ios'
        ENV.delete('GH_TOKEN')
        assert_raises(KeyError) { CompilerWarnings.run(['--publish']) }
        assert_equal 1, JSON.parse(File.read(CompilerWarnings::REPORT)).fetch('annotations').length
      ensure
        ENV.replace(previous)
      end
    end
  end

  def test_replaces_invalid_utf8_bytes_before_parsing
    File.binwrite(@log, "unrelated binary \xFF\n#{diagnostic(message: "Invalid byte \xFF")}\n")
    report = CompilerWarnings.collect(root: @root, logs: [@log], tracked_files: [@source])
    assert_equal "Invalid byte \uFFFD", report.fetch('annotations').first.fetch('message')
    assert report.fetch('annotations').first.fetch('message').valid_encoding?
  end

  def test_keeps_prefixed_linker_and_project_warnings
    lines = ['ld: warning: duplicate libraries', '/path/Project.xcodeproj: warning: Deployment target is old']
    report = collect(lines + lines)
    assert_equal lines.sort, report.fetch('unlocated_warnings')
    assert_match(/2 without source locations/, CompilerWarnings.summary(report))
  end

  def test_deduplicates_identical_line_annotations_at_different_columns
    report = collect([diagnostic(column: 1), diagnostic(column: 20)])
    assert_equal 1, report.fetch('annotations').length
  end

  def test_deduplicates_untracked_warnings_and_counts_them_when_no_repository_warnings_exist
    warning = diagnostic(path: 'DerivedData/Dependency.swift')
    report = collect([warning, warning])
    assert_empty report.fetch('annotations')
    assert_equal 1, report.fetch('untracked_warnings').length
    publish(report)
    assert_match(/Collected 1 unique compiler warnings/, @api.requests.last[2].fetch('output').fetch('summary'))
    assert_match(/1 in untracked files/, @api.requests.last[2].fetch('output').fetch('summary'))
  end

  def fixture_commit(*paths)
    assert system('git', 'add', '--', *paths)
    assert system('git', '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
                  '-c', 'user.name=Test', '-c', 'user.email=test@example.com', 'commit', '-qm', 'Fixture change')
    CompilerWarnings.git('rev-parse', 'HEAD').strip
  end

  def map_versions(head, built, lines)
    in_repository do
      File.write(@source, head.join("\n") + "\n")
      head_sha = fixture_commit(@source)
      File.write(@source, built.join("\n") + "\n")
      built_sha = fixture_commit(@source)
      report = collect(lines.map { |line| diagnostic(line: line) }).merge('sha' => built_sha)
      yield CompilerWarnings.for_pr_head(report, head_sha)
    end
  end

  def test_maps_lines_shifted_by_base_branch_insertions
    map_versions(%w[one two three four], %w[prefix one two three four], [4]) do |report|
      assert_equal 3, report.fetch('annotations').first.fetch('start_line')
      assert_equal 4, report.fetch('build_annotations').first.fetch('start_line')
      assert_empty report.fetch('unmapped_warnings')
    end
  end

  def test_maps_lines_around_base_branch_deletions
    map_versions(%w[one two three four], %w[one three four], [1, 2]) do |report|
      assert_equal [1, 3], report.fetch('annotations').map { |warning| warning.fetch('start_line') }
    end
  end

  def test_retains_changed_lines_in_the_report_instead_of_annotating_the_wrong_source
    map_versions(%w[one two three four], %w[one replaced three four], [2, 3]) do |report|
      assert_equal [3], report.fetch('annotations').map { |warning| warning.fetch('start_line') }
      assert_equal [2], report.fetch('unmapped_warnings').map { |warning| warning.fetch('start_line') }
      assert_equal 2, report.fetch('build_annotations').length
      assert_match(/1 without matching PR-head source lines/, CompilerWarnings.summary(report))
    end
  end

  def test_handles_multiple_hunks_and_insertions_at_the_start_of_a_file
    map_versions(%w[one two three four five], %w[prefix one two three five], [1, 4, 5]) do |report|
      assert_equal [3, 5], report.fetch('annotations').map { |warning| warning.fetch('start_line') }
      assert_equal [1], report.fetch('unmapped_warnings').map { |warning| warning.fetch('start_line') }
    end
  end

  def test_keeps_warnings_for_files_that_only_exist_in_the_merge_build_in_the_report
    in_repository do
      head_sha = CompilerWarnings.git('rev-parse', 'HEAD').strip
      path = 'Sources/BaseOnly.swift'
      File.write(path, "// only on the base branch\n")
      built_sha = fixture_commit(path)
      report = collect([diagnostic(path: path, line: 1)], [path]).merge('sha' => built_sha)
      mapped = CompilerWarnings.for_pr_head(report, head_sha)
      assert_empty mapped.fetch('annotations')
      assert_equal [path], mapped.fetch('unmapped_warnings').map { |warning| warning.fetch('path') }
    end
  end

  # Builds a merge of a PR that adds Sources/PROnly.swift into a base branch
  # that inserts a line at the top of @source. Like GitHub's PR merge commit,
  # the base is the first parent and the PR head the second. Returns the PR head.
  def merge_pr_into_base
    File.write(@source, "one\ntwo\nthree\nfour\n")
    common = fixture_commit(@source)
    assert system('git', 'checkout', '-qb', 'fixture-pr')
    File.write('Sources/PROnly.swift', "// PR change\n")
    pr_head = fixture_commit('Sources/PROnly.swift')
    assert system('git', 'checkout', '-qb', 'fixture-base', common)
    File.write(@source, "prefix\none\ntwo\nthree\nfour\n")
    fixture_commit(@source)
    assert system('git', '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
                  '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                  'merge', '--quiet', '--no-edit', 'fixture-pr')
    pr_head
  end

  def test_maps_a_real_merge_build_from_a_depth_two_checkout
    in_repository do
      pr_head = merge_pr_into_base
      report = collect([diagnostic(line: 4)]).merge('sha' => CompilerWarnings.git('rev-parse', 'HEAD').strip)
      clone = File.join(@root, 'shallow-copy')
      assert system('git', 'clone', '--quiet', '--depth=2', '--no-local', "file://#{@root}", clone)
      Dir.chdir(clone) do
        assert_equal 'true', CompilerWarnings.git('rev-parse', '--is-shallow-repository').strip
        assert_equal 'commit', CompilerWarnings.git('cat-file', '-t', pr_head).strip
        mapped = CompilerWarnings.for_pr_head(report, pr_head)
        assert_equal 3, mapped.fetch('annotations').first.fetch('start_line')
      end
    end
  end

  def test_publishes_only_warnings_in_files_changed_by_the_pr
    in_repository do
      pr_head = merge_pr_into_base
      FileUtils.mkdir_p('build')
      File.write('build/current.log', [diagnostic(line: 4), diagnostic(path: 'Sources/PROnly.swift', line: 1)].join("\n"))
      event_path = File.join(@root, 'event.json')
      File.write(event_path, JSON.generate('pull_request' => {
        'head' => { 'sha' => pr_head, 'repo' => { 'full_name' => 'wireapp/wire-ios' } }
      }))
      ENV['GITHUB_EVENT_PATH'] = event_path
      ENV['GITHUB_REPOSITORY'] = 'wireapp/wire-ios'
      ENV['GITHUB_RUN_ID'] = '123'
      api = FakeAPI.new
      CompilerWarnings.run(['--publish'], api: api)
      uploaded = api.requests.flat_map { |request| request[2].dig('output', 'annotations') || [] }
      assert_equal ['Sources/PROnly.swift'], uploaded.map { |warning| warning.fetch('path') }
      report = JSON.parse(File.read(CompilerWarnings::REPORT))
      assert_equal [[@source, 3]], report.fetch('unchanged_file_warnings').map { |warning| [warning.fetch('path'), warning.fetch('start_line')] }
      assert_match(/1 available inline, 1 in files not changed by the PR/, CompilerWarnings.summary(report))
    end
  end

  def test_does_not_filter_warnings_when_the_build_is_not_a_merge_commit
    in_repository do
      assert_nil CompilerWarnings.pr_changed_files(CompilerWarnings.git('rev-parse', 'HEAD').strip)
    end
  end

  def test_cleanup_failure_preserves_the_original_error_and_the_initial_neutral_check
    original = IOError.new('Upload response lost')
    api = FakeAPI.new
    api.define_singleton_method(:request) do |method, path, body|
      @requests << [method, path, body]
      raise original if body.dig('output', 'annotations')
      raise 'Cleanup also failed' if method == :patch

      { 'id' => 123 }
    end
    raised = assert_raises(IOError) do
      CompilerWarnings.publish(api: api, repository: 'wireapp/wire-ios', sha: 'built-sha',
                               name: 'Compiler warnings', report: collect([diagnostic]), details_url: 'https://example.com')
    end
    assert_same original, raised
    assert_equal 'completed', api.requests.first[2].fetch('status')
    assert_equal 'neutral', api.requests.first[2].fetch('conclusion')
  end

  def test_check_is_neutral_and_completed_even_before_uploading_annotations
    publish(collect([diagnostic]))
    assert_equal 'completed', @api.requests.first[2].fetch('status')
    assert_equal 'neutral', @api.requests.first[2].fetch('conclusion')
  end

  def assert_cancellation_cleanup(exception)
    api = FakeAPI.new
    api.define_singleton_method(:request) do |method, path, body|
      @requests << [method, path, body]
      raise exception if body.dig('output', 'annotations')

      { 'id' => 123 }
    end
    raised = assert_raises(exception.class) do
      CompilerWarnings.publish(api: api, repository: 'wireapp/wire-ios', sha: 'built-sha',
                               name: 'Compiler warnings', report: collect([diagnostic]), details_url: 'https://example.com')
    end
    assert_same exception, raised
    assert_equal 'neutral', api.requests.last[2].fetch('conclusion')
    assert_equal 'completed', api.requests.last[2].fetch('status')
  end

  def test_interrupt_completes_the_check_without_swallowing_the_interrupt
    assert_cancellation_cleanup(Interrupt.new('Cancelled'))
  end

  def test_signal_exception_completes_the_check_without_swallowing_the_signal
    assert_cancellation_cleanup(SignalException.new('TERM'))
  end

  class StubTransportAPI < CompilerWarnings::API
    attr_reader :calls, :delays

    def initialize(outcomes)
      super(token: 'fixture-token', base_url: 'https://api.github.com')
      @outcomes = outcomes
      @calls = []
      @delays = []
    end

    def perform(uri, request)
      @calls << [uri, request]
      outcome = @outcomes.shift
      raise outcome if outcome.is_a?(Exception)

      outcome
    end

    def sleep(seconds)
      @delays << seconds
    end
  end

  def http_response(status)
    response = Net::HTTPResponse::CODE_TO_OBJ.fetch(status.to_s).new('1.1', status.to_s, 'Fixture response')
    response.define_singleton_method(:body) { '{"id":123}' }
    response
  end

  def test_retries_transient_metadata_update_errors_with_bounded_backoff
    api = StubTransportAPI.new([Timeout::Error.new('Timeout'), http_response(502), http_response(200)])
    assert_equal({ 'id' => 123 }, api.request(:patch, '/check-runs/123', { 'conclusion' => 'success' }))
    assert_equal 3, api.calls.length
    assert_equal [1, 2], api.delays
  end

  def test_stops_retrying_after_three_attempts
    api = StubTransportAPI.new([http_response(503), http_response(503), http_response(503)])
    assert_raises(CompilerWarnings::API::HTTPError) do
      api.request(:patch, '/check-runs/123', { 'conclusion' => 'success' })
    end
    assert_equal 3, api.calls.length
  end

  def test_does_not_retry_authorization_errors
    api = StubTransportAPI.new([http_response(403)])
    assert_raises(CompilerWarnings::API::HTTPError) do
      api.request(:patch, '/check-runs/123', { 'conclusion' => 'success' })
    end
    assert_empty api.delays
  end

  def test_does_not_replay_a_check_creation_after_an_ambiguous_failure
    api = StubTransportAPI.new([http_response(503)])
    assert_raises(CompilerWarnings::API::HTTPError) { api.request(:post, '/check-runs', { 'name' => 'Warnings' }) }
    assert_equal 1, api.calls.length
    assert_empty api.delays
  end

  def test_does_not_duplicate_appended_annotations_after_a_lost_response
    api = StubTransportAPI.new([Timeout::Error.new('Response lost')])
    assert_raises(Timeout::Error) do
      api.request(:patch, '/check-runs/123', { 'output' => { 'annotations' => [{}] } })
    end
    assert_equal 1, api.calls.length
    assert_empty api.delays
  end
end
