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

  def test_ignores_dependencies_generated_files_and_paths_outside_repository
    report = collect([
      diagnostic(path: 'DerivedData/CachedSwiftPackages/Dependency.swift'),
      diagnostic(path: File.join(@root, '..', 'External.swift')),
      diagnostic(path: 'Sources/../Untracked.swift'),
      diagnostic(path: @source)
    ])
    assert_equal [@source], report.fetch('annotations').map { |annotation| annotation.fetch('path') }
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
    assert_equal ['Linker warning'], report.fetch('unlocated_warnings')
  end

  def test_publishes_hundreds_of_warnings_without_truncation_in_batches_of_50
    report = collect((1..327).map { |line| diagnostic(line: line) })
    publish(report)
    batches = @api.requests.select { |request| request[2].dig('output', 'annotations') }
    assert_equal [50, 50, 50, 50, 50, 50, 27], batches.map { |request| request[2]['output']['annotations'].length }
    assert_equal report.fetch('annotations'), batches.flat_map { |request| request[2]['output']['annotations'] }
    assert_equal 'built-sha', @api.requests.first[2].fetch('head_sha')
    assert_equal({ 'status' => 'completed', 'conclusion' => 'success' }, @api.requests.last[2])
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
      File.write(event_path, JSON.generate('pull_request' => { 'head' => { 'repo' => { 'full_name' => 'wireapp/wire-ios' } } }))
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
end
