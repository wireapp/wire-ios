require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'timeout'

class RunUITestsWithTimeoutTest < Minitest::Test
  RUNNER = File.expand_path('../run_ui_tests_with_timeout.rb', __dir__)

  def setup
    @root = Dir.mktmpdir('ui-test-timeout')
    @log = File.join(@root, 'wrapper.log')
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_preserves_success_and_failure_status_and_arguments_with_spaces
    success = run_wrapper('2', 'ruby', '-e', 'print ARGV.join("|")', 'first value', 'second value')
    assert_equal 0, success.exitstatus
    assert_includes success.stdout, 'first value|second value'

    failure = run_wrapper('2', 'ruby', '-e', 'STDOUT.sync = true; puts "failure output"; exit 7')
    assert_equal 7, failure.exitstatus
    assert_includes File.read(@log), 'failure output'
  end

  def test_times_out_when_child_closes_stdout_and_stays_alive
    code = 'STDOUT.sync = true; STDERR.sync = true; puts "ready"; STDOUT.close; STDERR.close; sleep 10'
    result = run_wrapper('1', 'ruby', '-e', code)
    assert_equal 124, result.exitstatus
    assert_includes result.stdout, 'ready'
    assert_includes File.read(@log), 'Timed out'
  end

  def test_timeout_kills_a_term_ignoring_descendant
    child_pid_file = File.join(@root, 'child.pid')
    child_code = 'Signal.trap("TERM", "IGNORE"); File.write(ARGV[0], Process.pid); loop { sleep 1 }'
    parent_code = 'pid = Process.fork { exec RbConfig.ruby, "-e", ARGV[1], ARGV[0] }; ' +
                  'puts "child=#{pid}"; sleep 10'

    result = run_wrapper('1.5', 'ruby', '-rrbconfig', '-e', parent_code, child_pid_file, child_code)
    assert_equal 124, result.exitstatus
    assert_process_stopped(Integer(File.read(child_pid_file)))
  end

  def test_timeout_kills_term_and_hup_ignoring_child_in_pty_process_group
    child_pid_file = File.join(@root, 'pty-child.pid')
    child_code = 'Signal.trap("TERM", "IGNORE"); Signal.trap("HUP", "IGNORE"); ' +
                 'File.write(ARGV[0], Process.pid); loop { sleep 1 }'
    parent_code = 'require "pty"; PTY.spawn(RbConfig.ruby, "-e", ARGV[1], ARGV[0]) { |_reader, _writer, pid| ' +
                  'STDOUT.sync = true; puts "pty child #{pid}"; sleep 10 }'

    result = run_wrapper('2', 'ruby', '-rrbconfig', '-e', parent_code, child_pid_file, child_code)
    assert_equal 124, result.exitstatus
    assert File.exist?(child_pid_file), 'PTY child should start before timeout'
    assert_process_stopped(Integer(File.read(child_pid_file)))
  end

  def test_flushes_partial_log_while_child_runs_and_keeps_it_after_timeout
    command = ['ruby', '-e', 'STDOUT.sync = true; puts "partial marker"; print "trailing marker"; sleep 10']
    Open3.popen2e(*wrapper_command('1.5', *command)) do |_stdin, output, wait_thread|
      output.gets
      output.gets
      assert Process.kill(0, wait_thread.pid)
      assert_includes File.read(@log), 'partial marker'
      assert_equal 124, wait_thread.value.exitstatus
    end
    assert_includes File.read(@log), 'partial marker'
    assert_includes File.read(@log), 'trailing marker'
  end

  def test_redacts_secrets_split_across_child_writes
    secret = 'SplitSecretValue9'
    env_file = File.join(@root, 'env.xcconfig')
    File.write(env_file, "API_TOKEN = #{secret}\n")
    inherited_secret = 'InheritedFakeSecret7'
    first_half, second_half = secret[0...8], secret[8..]
    code = "STDOUT.sync = true; print #{first_half.inspect}; sleep 0.05; puts #{second_half.inspect}; puts ENV.fetch('FAKE_AUTH_TOKEN')"

    result = run_wrapper('2', '--redact-env-file', env_file, 'ruby', '-e', code,
                         env: { 'FAKE_AUTH_TOKEN' => inherited_secret })
    assert_equal 0, result.exitstatus
    assert_includes result.stdout, '***'
    refute_includes result.stdout, secret
    refute_includes result.stdout, inherited_secret
    refute_includes File.read(@log), secret
    refute_includes File.read(@log), inherited_secret
  end

  def test_redacts_generated_login_typing_cleanup_and_password_diagnostics
    lines = [
      'login: email generated-user@example.test and password GeneratedPass9!',
      'Type text "GeneratedPass9!"',
      'Failed to clean up user generated-user@example.test: request failed',
      'password: PasswordDiagnostic8!'
    ]
    result = run_wrapper('2', 'ruby', '-e', "STDOUT.sync = true; puts #{lines.join("\n").inspect}")
    log = File.read(@log)

    assert_equal 0, result.exitstatus
    [result.stdout, log].each do |output|
      refute_includes output, 'generated-user@example.test'
      refute_includes output, 'GeneratedPass9!'
      refute_includes output, 'PasswordDiagnostic8!'
    end
  end

  def test_term_cancels_early_and_cleans_any_started_process_group
    child_pid_file = File.join(@root, 'cancel-child.pid')
    child_code = 'Signal.trap("TERM", "IGNORE"); File.write(ARGV[0], Process.pid); loop { sleep 1 }'
    parent_code = 'pid = Process.fork { exec RbConfig.ruby, "-e", ARGV[1], ARGV[0] }; STDOUT.sync = true; puts "cancel marker #{pid}"; sleep 10'

    Open3.popen2e(*wrapper_command('10', 'ruby', '-rrbconfig', '-e', parent_code, child_pid_file, child_code)) do |_stdin, output, wait_thread|
      started_line = output.gets
      assert_includes started_line, '[ui-tests] Started'
      Process.kill('TERM', wait_thread.pid)

      assert_equal 143, wait_thread.value.exitstatus
      assert_includes File.read(@log), '[ui-tests] Cancelled'
      if File.exist?(child_pid_file)
        assert_process_stopped(Integer(File.read(child_pid_file)))
      end
    end
    assert_operator File.read(@log).length, :>, 0
  end

  private

  def wrapper_command(timeout, *arguments)
    options = arguments.first == '--redact-env-file' ? arguments.shift(2) : []
    [RbConfig.ruby, RUNNER, '--timeout-seconds', timeout, '--log', @log, *options, '--', *arguments]
  end

  def run_wrapper(timeout, *arguments, env: {})
    stdout, stderr, status = Open3.capture3(env, *wrapper_command(timeout, *arguments))
    Struct.new(:stdout, :stderr, :status) do
      def exitstatus
        status.exitstatus
      end
    end.new(stdout, stderr, status)
  end

  def assert_process_stopped(pid)
    Timeout.timeout(3) do
      loop do
        begin
          Process.kill(0, pid)
          state = `ps -o stat= -p #{pid}`.strip
          break if state.empty? || state.start_with?('Z')
        rescue Errno::ESRCH
          break
        end
        sleep 0.05
      end
    end
  end
end
