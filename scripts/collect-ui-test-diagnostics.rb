#!/usr/bin/env ruby
require 'fileutils'
require 'json'
require 'tempfile'
require 'time'
require 'timeout'

class UITestDiagnostics
  DIRECTORY = 'build/ui-test-diagnostics'
  SAMPLE_INTERVAL = 10
  COLLECTION_BUDGET = 240
  EVIDENCE_PATTERN = /
    No\ matching\ device|launchSession.*should\ not\ be\ nil|ASSERTION\ FAILURE|Abort\ trap|
    TEST\ FAILED|TEST\ SUCCEEDED|Testing\ failed:|
    (?:Unable|Failed)\ to\ (?:boot|launch)|SBMainWorkspace|BSErrorCodeDescription.*Busy
  /ix

  def initialize
    FileUtils.mkdir_p(DIRECTORY)
    @state_path = "#{DIRECTORY}/state.json"
    @state = File.exist?(@state_path) ? JSON.parse(File.read(@state_path)) : {
      'started_at' => Time.now.utc.iso8601, 'devices' => {}, 'observed_clones' => {}
    }
  end

  def event(message)
    File.open("#{DIRECTORY}/timeline.log", 'a') { |file| file.puts("#{Time.now.utc.iso8601} #{message}") }
  end

  def save_state
    File.write("#{@state_path}.tmp", JSON.pretty_generate(@state))
    File.rename("#{@state_path}.tmp", @state_path)
  end

  # Each diagnostic command has its own deadline and process group.
  def run(*command, seconds: 15, output: nil)
    return nil if @monitoring && File.exist?("#{DIRECTORY}/stop")

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    if @collection_deadline
      remaining = @collection_deadline - started
      if remaining <= 0
        event("COLLECTION TIMEOUT budget exhausted; skipped #{command.first(3).join(' ')}")
        return nil
      end
      seconds = [seconds, remaining].min
    end
    Tempfile.create('ui-diagnostics-output') do |stdout|
      Tempfile.create('ui-diagnostics-error') do |stderr|
        destination = output ? File.open(output, 'w') : stdout
        begin
          pid = Process.spawn(*command, out: destination, err: stderr, pgroup: true)
          _, status = Timeout.timeout(seconds) { Process.wait2(pid) }
          elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
          unless status.success?
            event("COLLECTION ERROR #{command.first(3).join(' ')}: exit=#{status.exitstatus} signal=#{status.termsig} elapsed=#{elapsed.round(1)}s")
            stderr.rewind
            event(stderr.read.strip)
            return nil
          end
          stdout.rewind
          output ? true : stdout.read
        rescue Timeout::Error
          event("COLLECTION TIMEOUT #{command.first(3).join(' ')}: exceeded #{seconds}s")
          begin
            Process.kill('KILL', -pid)
            Process.wait(pid)
          rescue Errno::ESRCH, Errno::ECHILD
            # The command may have exited at the deadline.
          end
          nil
        ensure
          destination.close if output
        end
      end
    end
  rescue StandardError => error
    event("COLLECTION ERROR #{command.first(3).join(' ')}: #{error.class}: #{error.message}")
    nil
  end

  def snapshot
    sets = { 'default' => [] }
    test_set = File.expand_path('~/Library/Developer/XCTestDevices')
    test_set_present = File.directory?(test_set)
    if @state['test_set_present'] != test_set_present
      event("DEVICE SET XCTestDevices directory #{test_set_present ? 'present' : 'absent'}")
    end
    @state['test_set_present'] = test_set_present
    sets['XCTestDevices'] = ['--set', test_set] if test_set_present
    booted_clones = []
    sets.each do |name, arguments|
      raw = run('xcrun', 'simctl', *arguments, 'list', 'devices', '--json')
      next unless raw

      begin
        devices = JSON.parse(raw).fetch('devices').flat_map do |runtime, list|
          list.map { |device| [device.fetch('udid'), device.slice('name', 'state', 'isAvailable', 'availabilityError').merge('runtime' => runtime)] }
        end.to_h
      rescue JSON::ParserError, KeyError => error
        event("COLLECTION ERROR #{name}: invalid device listing: #{error.message}")
        next
      end
      @state['base_name'] ||= devices.dig(ENV['IOS_SIM_ID'], 'name')
      previous = @state['devices'][name] || {}
      devices.each do |id, device|
        if previous[id] != device
          event("DEVICE #{name} #{id} #{device['name']}: #{previous.dig(id, 'state') || 'first seen'} -> #{device['state']} available=#{device['isAvailable']} runtime=#{device['runtime']} #{device['availabilityError']}")
        end
        if @state['base_name'] && device['name'].match?(/\AClone \d+ of #{Regexp.escape(@state['base_name'])}\z/)
          seen = Time.now.utc.iso8601
          first_seen = @state['observed_clones'].dig(id, 'first_seen') || seen
          @state['observed_clones'][id] = device.merge('set' => name, 'first_seen' => first_seen, 'last_seen' => seen)
          booted_clones << id if device['state'] == 'Booted'
        end
      end
      (previous.keys - devices.keys).each do |id|
        event("DEVICE NO LONGER LISTED #{name} #{id} #{previous[id]['name']} (not proof of deletion)")
      end
      @state['devices'][name] = devices
      @state['last_successful_inventory'] ||= {}
      @state['last_successful_inventory'][name] = Time.now.utc.iso8601
      File.write("#{DIRECTORY}/devices-#{name}.json", JSON.pretty_generate(devices))
    end
    @state['max_booted_clones'] = [@state.fetch('max_booted_clones', 0), booted_clones.uniq.length].max
    save_state

    File.open("#{DIRECTORY}/resources.log", 'a') do |file|
      file.puts("\n#{Time.now.utc.iso8601}")
      file.puts(run('sysctl', 'vm.swapusage', 'vm.loadavg'))
      file.puts(run('vm_stat'))
      file.puts(run('df', '-k', '.'))
      processes = run('ps', '-axo', 'pid=,ppid=,%cpu=,rss=,comm=')
      file.puts('Relevant processes: PID PPID CPU% RSS(KiB) EXECUTABLE (no command arguments)')
      file.puts(processes.to_s.lines.grep(/xcodebuild|CoreSimulator|Simulator\.app|launchd_sim|testmanagerd|WireUITests-Runner|Runner\.Worker/))
    end
  end

  def monitor
    @monitoring = true
    event("MONITOR START base=#{ENV['IOS_SIM_ID']} requested_workers=#{ENV['UITEST_PARALLEL_WORKERS']} snapshot_interval=#{SAMPLE_INTERVAL}s (commands may take longer)")
    save_state
    File.open("#{DIRECTORY}/environment.txt", 'w') do |file|
      file.puts("Run: #{ENV['GITHUB_RUN_ID']} attempt: #{ENV['GITHUB_RUN_ATTEMPT']}")
      file.puts("Commit: #{ENV['GITHUB_SHA']} job: #{ENV['GITHUB_JOB']}")
      file.puts("Runner: #{ENV['RUNNER_NAME']} base simulator: #{ENV['IOS_SIM_ID']}")
      file.puts("Requested workers: #{ENV['UITEST_PARALLEL_WORKERS']}")
      file.puts(run('sw_vers'))
      file.puts(run('xcodebuild', '-version'))
      file.puts(run('xcode-select', '-p'))
      file.puts(run('sysctl', 'hw.logicalcpu', 'hw.memsize'))
      file.puts(run('xcrun', 'simctl', 'list', 'runtimes', '--json'))
    end
    until File.exist?("#{DIRECTORY}/stop")
      snapshot_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      snapshot
      pause = [SAMPLE_INTERVAL - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - snapshot_started), 0].max
      pause.ceil.times do
        break if File.exist?("#{DIRECTORY}/stop")
        sleep 1
      end
    end
    event('MONITOR STOP')
  ensure
    @monitoring = false
  end

  def collect(outcome)
    collection_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # Leave time for summary/file writes before the workflow's five-minute limit.
    @collection_deadline = collection_started + COLLECTION_BUDGET
    event("TEST STEP FINISHED outcome=#{outcome}; collecting before simulator cleanup")
    snapshot
    started = Time.iso8601(@state['started_at'])
    step_path = "#{DIRECTORY}/test-step.json"
    step = File.exist?(step_path) ? JSON.parse(File.read(step_path)) : {}
    finished = step['finished_at'] ? Time.iso8601(step['finished_at']) : nil
    evidence = []
    test_results = []
    Dir.glob('artifacts/**/*.xcresult').each_with_index do |path, index|
      next if File.mtime(path) < started

      result = run('xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', path, '--compact', seconds: 20)
      next unless result

      begin
        parsed = JSON.parse(result)
        File.write("#{DIRECTORY}/xcresult-#{index + 1}-summary.json", JSON.pretty_generate(parsed))
        test_results << "#{path}: status=#{parsed['result']} total=#{parsed['totalTestCount']} passed=#{parsed['passedTests']} failed=#{parsed['failedTests']} skipped=#{parsed['skippedTests']}"
        if parsed['startTime'] && parsed['finishTime']
          test_results << "  Xcode-reported elapsed: #{(parsed['finishTime'] - parsed['startTime']).round(1)}s"
        end
        parsed.fetch('testFailures', []).first(10).each do |failure|
          test_results << "  #{failure['testIdentifierString']}: #{failure['failureText'].to_s.gsub(/\s+/, ' ')[0, 500]}"
        end
        test_results << '  Full failure messages and any additional failures: xcresult summary JSON.'
      rescue JSON::ParserError => error
        event("COLLECTION ERROR xcresult summary: #{error.message}")
      end
    end
    FileUtils.mkdir_p("#{DIRECTORY}/test-logs")
    Dir.glob('build/*.log').each do |path|
      next if File.mtime(path) < started
      FileUtils.cp(path, "#{DIRECTORY}/test-logs")
      File.foreach(path) do |line|
        clean = line.gsub(/\e\[[0-9;]*m/, '').strip
        if clean.match?(EVIDENCE_PATTERN)
          evidence << "#{File.basename(path)}: #{clean}"
        end
      end
    end
    File.write("#{DIRECTORY}/failure-evidence.log", evidence.uniq.join("\n") + "\n")
    summary = [
      'UI test diagnostics (all timestamps UTC)',
      "Test step outcome: #{outcome}",
      "Fastlane shell exit code: #{step.fetch('exit_code', 'not recorded (step may have been interrupted)')} (may wrap a different xcodebuild exit code)",
      "Observation started: #{@state['started_at']}",
      "Test command finished: #{step.fetch('finished_at', 'not recorded')}",
      "Elapsed test step: #{finished ? "#{(finished - started).round}s" : 'unknown'} (includes build/setup, excludes post-test diagnostics)",
      "Requested workers: #{ENV['UITEST_PARALLEL_WORKERS']}",
      "Largest sampled number of booted job clones: #{@state.fetch('max_booted_clones', 0)} (not proof of active tests)",
      "Observed job clone IDs: #{@state['observed_clones'].length} (may include replacements, not simultaneous worker count)",
      *@state['observed_clones'].map { |id, device| "  #{device['name']} | #{id} | first seen=#{device['first_seen']} | last seen=#{device['last_seen']} | last state=#{device['state']}" },
      '',
      'Test results:',
      *(test_results.empty? ? ['No readable xcresult summary. Check collection errors; run may have ended before results were finalized.'] : test_results),
      '',
      'Selected evidence from raw test logs:',
      *(evidence.empty? ? ['No matching signatures found. Check xcresult and raw logs; absence is not proof of health.'] : evidence.uniq.first(20)),
      'See failure-evidence.log for all matching lines.',
      '',
      'How to read this artifact:',
      'timeline.log: device state changes, missing devices, and diagnostic collection errors/timeouts.',
      'resources.log: timestamped memory, swap, free disk and relevant process IDs/CPU/RSS.',
      'devices-*.json: last successful inventory for each device set; state.json records inventory timestamps and observed job clones.',
      'test-logs/: raw xcodebuild logs. Existing XCResults artifact contains test activity and failure details.',
      'xcresult-*-summary.json: available test counts, durations, devices and failure messages from Xcode.',
      'failure-diagnostics/: simulator bundle and new crash reports, collected only after an unsuccessful test step.',
      '',
      'Error meanings (not automatic root-cause diagnoses):',
      'CoreSimulator 404 / No matching device: requested device could not be resolved in that device set.',
      'launchSession should not be nil: Xcode internal assertion during simulator launch/install.',
      'Unable/Failed to boot or launch: startup failed; accompanying error domain/code gives more detail.',
      'SBMainWorkspace / Busy: inspect accompanying launch error; a Busy response alone does not identify its cause.',
      'Abort trap / exit 134: process aborted; exit 65 alone is a general build/test failure.',
      'Booted is not proof of test execution. Use xcresult to confirm work on each simulator.',
      'Snapshots are periodic; a missing device may be normal Xcode cleanup. Correlate timestamps with failures.',
      'Diagnostics can narrow causes, but cannot prove who removed a device or capture events after host loss.'
    ]
    File.write("#{DIRECTORY}/summary.txt", summary.join("\n") + "\n")
    puts "UI test diagnostics: outcome=#{outcome}; observed job clones=#{@state['observed_clones'].length}. See summary.txt in artifact."
    return if outcome == 'success'

    failure_directory = "#{DIRECTORY}/failure-diagnostics"
    FileUtils.mkdir_p(failure_directory)
    crash_report_count = 0
    [File.expand_path('~/Library/Logs/DiagnosticReports'), '/Library/Logs/DiagnosticReports'].each_with_index do |directory, index|
      Dir.glob("#{directory}/*.{ips,crash}").each do |path|
        next unless File.basename(path).match?(/\A(?:com\.apple\.)?(xcodebuild|CoreSimulator|Simulator|launchd_sim|testmanagerd|WireUITests|Wire(?=[_.-]))/i)
        next if File.mtime(path) < started
        FileUtils.cp(path, "#{failure_directory}/#{index}-#{File.basename(path)}")
        crash_report_count += 1
      end
    end
    event("NEW RELEVANT CRASH REPORTS copied=#{crash_report_count} (zero does not rule out a crash)")
    test_set = File.expand_path('~/Library/Developer/XCTestDevices')
    sets = { 'default' => [] }
    if File.directory?(test_set)
      sets['XCTestDevices'] = ['--set', test_set]
    else
      event('XCTestDevices diagnostic bundle skipped: device set directory absent')
    end
    sets.each do |name, arguments|
      directory = "#{failure_directory}/#{name}"
      FileUtils.mkdir_p(directory)
      event("SIMULATOR DIAGNOSE START set=#{name} (45s collection limit, includes shutdown device logs, no app data containers)")
      collected = run('xcrun', 'simctl', *arguments, 'diagnose', '-b', '--all-logs', '--timeout=45',
                      "--output=#{File.expand_path(directory)}", seconds: 65, output: "#{directory}/collection.log")
      event("SIMULATOR DIAGNOSE END set=#{name}; check #{name}/collection.log and collection errors above")
      File.open("#{DIRECTORY}/summary.txt", 'a') do |file|
        file.puts("\nSimulator diagnostics [#{name}]: #{collected ? 'completed; inspect collection.log for partial results' : 'failed or timed out; see timeline.log'}")
        file.puts('Includes available shutdown-device logs; cannot recover device data already deleted.')
      end
    end
  ensure
    @collection_deadline = nil
    if File.exist?("#{DIRECTORY}/summary.txt")
      timeline = File.read("#{DIRECTORY}/timeline.log")
      File.open("#{DIRECTORY}/summary.txt", 'a') do |file|
        file.puts("Collection elapsed: #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - collection_started).round(1)}s")
        file.puts("Collection errors/timeouts: #{timeline.scan(/COLLECTION (?:ERROR|TIMEOUT)/).length}")
        file.puts('Monitor did not record a clean stop; periodic evidence may be incomplete.') unless timeline.include?('MONITOR STOP')
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  diagnostics = UITestDiagnostics.new
  begin
    case ARGV[0]
    when 'monitor' then diagnostics.monitor
    when 'collect' then diagnostics.collect(ARGV.fetch(1))
    else abort 'Usage: collect-ui-test-diagnostics.rb monitor | collect <test-step-outcome>'
    end
  rescue StandardError => error
    diagnostics.event("COLLECTION ERROR #{error.class}: #{error.message}")
    warn 'UI test diagnostic collection incomplete; see timeline.log.'
    exit 1
  end
end
