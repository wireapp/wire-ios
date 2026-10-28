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

# Runs UI tests on several simulators at once. Each simulator is created, seeded and checked to launch an app
# before it takes tests, and the app is built once with `build-for-testing`. The tests are split into small batches
# (a class with more than MAX_TESTS_PER_BATCH tests is cut up) held in one shared queue. Each shard, one per
# simulator, takes the next batch when it is free and runs it with its own `xcodebuild test-without-building`; at
# the end the batch results of a shard are merged into one `<result-dir>/shard-<n>/<scheme>.xcresult`.
#
# Exit status: 0 when every test ran and passed, 1 otherwise.

require "fileutils"
require "open3"
require "optparse"
require "shellwords"

ROOT = File.expand_path("..", __dir__)
$stdout.sync = true

options = {
    workers: 2,
    test_iterations: 1,
    build_settings: [],
    workspace: "wire-ios-mono.xcworkspace",
    configuration: "Debug"
}

OptionParser.new do |parser|
    parser.banner = "Usage: run_sharded_uitests.rb [options]"
    parser.on("--workers N", Integer, "Number of shards (one simulator each)") { |value| options[:workers] = value }
    parser.on("--tests-file PATH", "File with one test identifier (Target/Class/method) per line") { |value| options[:tests_file] = value }
    parser.on("--base-simulator UDID", "Booted and seeded simulator used by the first shard") { |value| options[:base_simulator] = value }
    parser.on("--device-type NAME", "Device type for extra simulators, e.g. 'iPhone 17'") { |value| options[:device_type] = value }
    parser.on("--runtime NAME", "Runtime for extra simulators, e.g. 'iOS26.5'") { |value| options[:runtime] = value }
    parser.on("--os-version VERSION", "OS version used in the build destination") { |value| options[:os_version] = value }
    parser.on("--workspace PATH") { |value| options[:workspace] = value }
    parser.on("--scheme NAME") { |value| options[:scheme] = value }
    parser.on("--test-plan NAME") { |value| options[:test_plan] = value }
    parser.on("--configuration NAME") { |value| options[:configuration] = value }
    parser.on("--derived-data PATH") { |value| options[:derived_data] = value }
    parser.on("--packages-dir PATH") { |value| options[:packages_dir] = value }
    parser.on("--build-setting SETTING", "KEY=VALUE passed to the build, repeatable") { |value| options[:build_settings] << value }
    parser.on("--result-dir PATH", "Each shard writes <result-dir>/shard-<n>/<scheme>.xcresult") { |value| options[:result_dir] = value }
    parser.on("--log-dir PATH", "Raw xcodebuild logs") { |value| options[:log_dir] = value }
    parser.on("--published-log-dir PATH", "Copies of the logs with credentials replaced, safe to upload") { |value| options[:published_log_dir] = value }
    parser.on("--redact-env-file PATH", "env.xcconfig whose credential values are replaced in published logs") { |value| options[:redact_env_file] = value }
    parser.on("--test-iterations N", Integer, "Attempts per failing test, 1 disables retries") { |value| options[:test_iterations] = value }
    parser.on("--simulators-file PATH", "Created simulator ids are appended here so they can be cleaned up later") { |value| options[:simulators_file] = value }
end.parse!

%i[tests_file base_simulator device_type runtime os_version scheme test_plan derived_data result_dir log_dir simulators_file].each do |key|
    abort("Missing --#{key.to_s.tr('_', '-')}") if options[key].to_s.empty?
end

OUTPUT_LOCK = Mutex.new

def say(label, message)
    OUTPUT_LOCK.synchronize { puts("[#{label}] #{message}") }
end

# Runs a command, returns [output, success]. Stops it, and everything it started, after `timeout` seconds.
def run(*command, env: {}, timeout: 300)
    output = +""
    Open3.popen2e(env, *command, pgroup: true) do |_stdin, out, wait_thread|
        reader = Thread.new { out.each_line { |line| output << line } }
        unless wait_thread.join(timeout)
            terminate_process_group(wait_thread)
            reader.join(5)
            return ["#{output}\ntimed out after #{timeout}s", false]
        end
        reader.join
        return [output, wait_thread.value.success?]
    end
end

# The command runs in its own process group, so its children (e.g. simctl from the seeding script) stop with it.
# The parent leaving is not enough: a child that ignores TERM must still be killed.
def terminate_process_group(wait_thread)
    group = -wait_thread.pid
    Process.kill("TERM", group) rescue nil
    deadline = Time.now + 10
    sleep(0.2) while process_group_alive?(group) && Time.now < deadline
    Process.kill("KILL", group) rescue nil if process_group_alive?(group)
    wait_thread.join(5)
end

def process_group_alive?(group)
    Process.kill(0, group)
    true
rescue Errno::ESRCH
    false
rescue Errno::EPERM
    true
end

# Values of the credentials in env.xcconfig, longest first, so they can be replaced in logs that leave the machine.
def secret_values(env_file)
    return [] if env_file.to_s.empty? || !File.exist?(env_file)

    File.readlines(env_file).filter_map do |line|
        match = line.match(/\A\s*([A-Z0-9_]+)\s*=\s*(.+?)\s*\z/)
        match[2] if match && match[1].match?(/PASSWORD|AUTH|TOKEN|SECRET|USERNAME|EMAIL/) && match[2].length >= 4
    end.uniq.sort_by { |value| -value.length }
end

# A failed runner launch prints the test runner's environment, credentials included. The raw logs stay in the log
# directory; this writes a copy with those values replaced, which is what CI uploads.
def publish_log(raw_path, published_dir, secrets)
    return if published_dir.to_s.empty? || !File.exist?(raw_path)

    FileUtils.mkdir_p(published_dir)
    text = File.read(raw_path, encoding: "UTF-8", invalid: :replace, undef: :replace)
    secrets.each { |secret| text = text.gsub(secret, "***") }
    File.write(File.join(published_dir, File.basename(raw_path)), text)
end

def write_job_summary(lines)
    return if ENV["GITHUB_STEP_SUMMARY"].to_s.empty?

    File.open(ENV["GITHUB_STEP_SUMMARY"], "a") { |file| file.puts(lines) }
end

def run!(*command, env: {}, timeout: 300)
    output, success = run(*command, env: env, timeout: timeout)
    raise "#{command.first(3).join(' ')} failed: #{output.lines.last(3).join.strip}" unless success

    output
end

# Streams a long xcodebuild command with a label on every line, keeps the raw log, returns success.
def stream(label, command, log_path)
    formatter = system("command -v xcbeautify >/dev/null 2>&1") ? " | xcbeautify" : ""
    shell = "set -o pipefail; #{command.shelljoin} 2>&1 | tee #{log_path.shellescape}#{formatter}"
    Open3.popen2e("bash", "-c", shell) do |_stdin, out, wait_thread|
        out.each_line { |line| say(label, line.chomp) }
        wait_thread.value.success?
    end
end

MAX_TESTS_PER_BATCH = 5

# Splits the tests into batches for a shared queue. A class of up to MAX_TESTS_PER_BATCH tests stays whole; a bigger
# one is cut into the fewest batches that fit, of even size, so there is no tiny leftover. Biggest batches come first,
# so the long ones start early and the short ones fill the gaps at the end.
def chunk(identifiers)
    classes = identifiers.group_by { |identifier| identifier.split("/")[0..1].join("/") }
    batches = classes.values.flat_map do |tests|
        count = (tests.size / MAX_TESTS_PER_BATCH.to_f).ceil
        base, extra = tests.size.divmod(count)
        offset = 0
        Array.new(count) do |index|
            size = base + (index < extra ? 1 : 0)
            tests[offset, size].tap { offset += size }
        end
    end
    batches.sort_by.with_index { |tests, index| [-tests.size, index] }
end

# A booted simulator can refuse app launches while SpringBoard finishes starting up. Launching a system app checks
# for that, so wait until it works.
def wait_until_launchable(udid, timeout: 180)
    deadline = Time.now + timeout
    loop do
        _, launched = run("xcrun", "simctl", "launch", udid, "com.apple.Preferences", timeout: 60)
        if launched
            run("xcrun", "simctl", "terminate", udid, "com.apple.Preferences", timeout: 30)
            return
        end
        raise "simulator #{udid} did not accept an app launch within #{timeout}s" if Time.now >= deadline

        sleep(3)
    end
end

def prepare_simulator(udid)
    started = Time.now
    run("xcrun", "simctl", "boot", udid, timeout: 120) # fails harmlessly when already booted
    run!("xcrun", "simctl", "bootstatus", udid, "-b", timeout: 600)
    booted = Time.now
    output, seeded = run("bash", File.join(ROOT, "scripts/seed-simulator-media.sh"), env: { "IOS_SIM_ID" => udid }, timeout: 120)
    unless seeded
        load_average = `uptime`.strip[/load averages?: .*/]
        raise "seeding #{udid} failed after #{(Time.now - booted).round}s (#{load_average}):\n#{output.lines.last(10).join}"
    end
    wait_until_launchable(udid)
    say("shards", "simulator #{udid} ready: boot #{(booted - started).round}s, seed #{(Time.now - booted).round}s")
end

# Wait for slow preparation, but surface a dead producer instead of waiting on an empty queue forever.
def next_ready_simulator(ready_simulators, preparation_threads)
    loop do
        begin
            return ready_simulators.pop(true)
        rescue ThreadError
            preparation_threads.each { |thread| thread.value unless thread.alive? }
            if preparation_threads.none?(&:alive?)
                preparation_threads.each(&:value)
                raise "Simulator preparation ended without reporting all shards" if ready_simulators.empty?
            end
            sleep(0.5)
        end
    end
end

Dir.chdir(ROOT)
tests = File.readlines(options[:tests_file]).map(&:strip).reject(&:empty?).uniq
abort("No tests to run in #{options[:tests_file]}") if tests.empty?

batches = chunk(tests)
planned = [options[:workers], batches.size].min
say("shards", "#{tests.size} tests, #{planned} shards, #{batches.size} batches of up to #{MAX_TESTS_PER_BATCH} tests taken from a shared queue")
FileUtils.mkdir_p([options[:log_dir], options[:result_dir], File.dirname(options[:simulators_file])])

# Prepare extras one at a time alongside the build. Publish each simulator as it becomes ready,
# so it can join the test queue without waiting for the others.
ready_simulators = Queue.new
base_ready = Thread.new do
    simulator = begin
        wait_until_launchable(options[:base_simulator])
        options[:base_simulator]
    rescue => error
        error
    end
    ready_simulators << [1, simulator]
end
extras_ready = Thread.new do
    (2..planned).each do |index|
        udid = nil
        attempts = 0
        simulator = begin
            attempts += 1
            udid = run!("xcrun", "simctl", "create", "#{options[:base_simulator]}-shard-#{index}", options[:device_type], options[:runtime]).strip
            File.open(options[:simulators_file], "a") { |file| file.puts(udid) }
            prepare_simulator(udid)
            udid
        rescue => error
            if udid
                %w[shutdown delete].each do |action|
                    begin
                        run("xcrun", "simctl", action, udid, timeout: 60)
                    rescue => cleanup_error
                        say("shards", "could not #{action} simulator #{udid}: #{cleanup_error.message}")
                    end
                end
            end
            if attempts < 2
                say("shards", "simulator for shard #{index} failed: #{error.message.strip}\n  trying a new one")
                retry
            end
            error
        end
        ready_simulators << [index, simulator]
    end
end
[base_ready, extras_ready].each { |thread| thread.report_on_exception = false }

build_command = [
    "xcodebuild",
    "-workspace", options[:workspace],
    "-scheme", options[:scheme],
    "-configuration", options[:configuration],
    "-derivedDataPath", options[:derived_data],
    "-sdk", "iphonesimulator",
    "-destination", "platform=iOS Simulator,id=#{options[:base_simulator]},OS=#{options[:os_version]}",
    "-testPlan", options[:test_plan],
    "-disableAutomaticPackageResolution",
    "-collect-test-diagnostics", "never"
]
build_command += ["-clonedSourcePackagesDirPath", options[:packages_dir]] unless options[:packages_dir].to_s.empty?
build_command += options[:build_settings]
build_command << "build-for-testing"

secrets = secret_values(options[:redact_env_file])
build_log = File.join(options[:log_dir], "#{options[:scheme]}-build-for-testing.log")
built = stream("build", build_command, build_log)
publish_log(build_log, options[:published_log_dir], secrets)

unless built
    [base_ready, extras_ready].each(&:value)
    say("shards", "build-for-testing failed, no tests were run")
    exit(1)
end

xctestrun = Dir.glob(File.join(options[:derived_data], "Build/Products", "#{options[:scheme]}_#{options[:test_plan]}_*.xctestrun")).max_by { |path| File.mtime(path) }
if xctestrun.nil?
    [base_ready, extras_ready].each(&:value)
    abort("[shards] no .xctestrun for #{options[:scheme]}/#{options[:test_plan]} in #{options[:derived_data]}")
end

# The runner can still be refused on a simulator that just opened Settings fine; such a batch ran no test, so
# running it once more costs little.
RUNNER_LAUNCH_FAILURE = /Failed to install or launch the test runner|Application failed preflight checks/.freeze
TEST_STARTED = /Test Case '.*' started/.freeze

launch_refused = ->(text) { text.match?(RUNNER_LAUNCH_FAILURE) && !text.match?(TEST_STARTED) }

# Every shard takes the next batch from this queue when it is free, so a shard that got short batches simply
# takes more of them. `in_flight` keeps shards waiting while a batch could still come back to the queue.
queue_lock = Mutex.new
queue = batches.each_with_index.map { |batch_tests, index| { number: index + 1, tests: batch_tests, launch_failures: 0 } }
in_flight = 0
alive = 0
pending_simulators = planned

take_batch = lambda do
    loop do
        batch, busy = queue_lock.synchronize do
            taken = queue.shift
            in_flight += 1 if taken
            [taken, in_flight]
        end
        return batch if batch
        return nil if busy.zero?

        sleep(5)
    end
end

finish_batch = ->(batch, requeue: false) do
    queue_lock.synchronize do
        in_flight -= 1
        queue.unshift(batch) if requeue
    end
end

# Final outcome of each test in an xcodebuild log; a test that failed and then passed on retry counts as passed.
def test_outcomes(log)
    log.scan(/Test Case '(.+?)' (passed|failed) \(/).to_h { |name, outcome| [name, outcome == "passed"] }
end

# Combines the result bundles of a shard's batches into the single bundle the reports expect.
def merge_bundles(bundles, target)
    FileUtils.rm_rf(target)
    FileUtils.mkdir_p(File.dirname(target))
    if bundles.size == 1
        FileUtils.mv(bundles.first, target)
        return true
    end

    _, merged = run("xcrun", "xcresulttool", "merge", *bundles, "--output-path", target, timeout: 900)
    merged
end

worker_threads = []
planned.times do
    number, simulator = next_ready_simulator(ready_simulators, [base_ready, extras_ready])
    queue_lock.synchronize do
        pending_simulators -= 1
        alive += 1 unless simulator.is_a?(Exception)
    end
    if simulator.is_a?(Exception)
        say("shards", "simulator for shard #{number} is not usable, continuing without it: #{simulator.message}")
        next
    end

    worker_threads << Thread.new do
        label = "shard #{number}"
        say(label, "simulator #{simulator} ready, joining the shared test queue")
        shard_dir = File.join(options[:result_dir], "shard-#{number}")
        batches_dir = File.join(options[:log_dir], "shard-#{number}-batches")
        FileUtils.rm_rf([shard_dir, batches_dir])
        FileUtils.mkdir_p(batches_dir)

        done = []
        retired = false
        started = Time.now
        while (batch = take_batch.call)
            batch_label = "#{label} batch #{batch[:number]}"
            result_bundle = File.join(batches_dir, "batch-#{batch[:number]}.xcresult")
            log_path = File.join(options[:log_dir], "#{options[:scheme]}-shard-#{number}-batch-#{batch[:number]}.log")

            command = [
                "xcodebuild", "test-without-building",
                "-xctestrun", xctestrun,
                "-destination", "platform=iOS Simulator,id=#{simulator}",
                "-derivedDataPath", File.join(options[:log_dir], "shard-#{number}-DerivedData"),
                "-resultBundlePath", result_bundle,
                "-collect-test-diagnostics", "never",
                "-parallel-testing-enabled", "NO"
            ]
            command += ["-retry-tests-on-failure", "-test-iterations", options[:test_iterations].to_s] if options[:test_iterations] > 1
            command += batch[:tests].map { |identifier| "-only-testing:#{identifier}" }

            batch_started = Time.now
            say(batch_label, "#{batch[:tests].size} tests on simulator #{simulator}")
            passed = stream(batch_label, command, log_path)
            log = File.exist?(log_path) ? File.read(log_path, encoding: "UTF-8", invalid: :replace) : ""
            relaunched = !passed && launch_refused.call(log)
            if relaunched
                say(batch_label, "test runner did not launch and no test ran, running this batch once more")
                # Keep the first attempt for debugging, outside the results directory so reports ignore it.
                # A result bundle is a directory: moving it onto an earlier run's copy would nest it inside, so replace that copy.
                first_log = log_path.sub(/\.log\z/, "-attempt-1.log")
                first_bundle = File.join(options[:log_dir], "#{options[:scheme]}-shard-#{number}-batch-#{batch[:number]}-attempt-1.xcresult")
                FileUtils.rm_rf([first_log, first_bundle])
                FileUtils.mv(log_path, first_log)
                FileUtils.mv(result_bundle, first_bundle) if File.exist?(result_bundle)
                publish_log(first_log, options[:published_log_dir], secrets)
                begin
                    wait_until_launchable(simulator)
                rescue => error
                    say(batch_label, error.message)
                end
                passed = stream(batch_label, command, log_path)
                log = File.exist?(log_path) ? File.read(log_path, encoding: "UTF-8", invalid: :replace) : ""
            end
            publish_log(log_path, options[:published_log_dir], secrets)

            # Refused twice with no test run: this simulator is bad. Hand the batch to another shard rather than
            # let this one burn through the whole queue.
            retire = !passed && relaunched && launch_refused.call(log) && batch[:launch_failures].zero? &&
                queue_lock.synchronize do
                    if alive > 1 || pending_simulators.positive?
                        alive -= 1
                        true
                    else
                        false
                    end
                end
            if retire
                say(batch_label, "simulator #{simulator} keeps refusing the runner, giving the batch to another shard")
                FileUtils.rm_rf(result_bundle)
                batch[:launch_failures] += 1
                finish_batch.call(batch, requeue: true)
                retired = true
                break
            end

            finish_batch.call(batch)
            done << { number: batch[:number], tests: batch[:tests].size, passed: passed, relaunched: relaunched,
                      outcomes: test_outcomes(log),
                      bundle: (result_bundle if File.exist?(result_bundle)),
                      minutes: ((Time.now - batch_started) / 60).round(1) }
        end
        queue_lock.synchronize { alive -= 1 } unless retired
        say(label, "no batches left to run") if done.empty? && !retired

        bundles = done.filter_map { |entry| entry[:bundle] }
        merged = true
        unless bundles.empty?
            target = File.join(shard_dir, "#{options[:scheme]}.xcresult")
            merged = merge_bundles(bundles, target)
            unless merged
                # Keep every batch's results rather than lose them: reports read all bundles in the shard directory.
                say(label, "merging result bundles failed, keeping them separate")
                FileUtils.mkdir_p(shard_dir)
                bundles.each { |bundle| FileUtils.cp_r(bundle, File.join(shard_dir, File.basename(bundle))) }
            end
        end
        {
            number: number, tests: done.sum { |entry| entry[:tests] },
            outcomes: done.map { |entry| entry[:outcomes] }.reduce({}, :merge),
            passed: done.all? { |entry| entry[:passed] },
            relaunched: done.count { |entry| entry[:relaunched] }, merged: merged, retired: retired,
            minutes: ((Time.now - started) / 60).round(1)
        }
    end
end
[base_ready, extras_ready].each(&:value)

if worker_threads.size < planned
    message = "Only #{worker_threads.size} of #{planned} simulators became ready"
    say("shards", message)
    write_job_summary("> [!WARNING]\n> UITest shards: #{message}")
end
results = worker_threads.map(&:value).sort_by { |result| result[:number] }

# Batches left in the queue had no usable worker left to take them.
unrun = queue.sum { |batch| batch[:tests].size }
summary = results.map do |result|
    ran = result[:outcomes].size
    passed = result[:outcomes].values.count(true)
    failed = ran - passed
    missing = result[:tests] - ran
    "shard #{result[:number]}: #{result[:tests]} tests, #{passed} passed, #{failed} failed" +
        (missing.positive? ? ", #{missing} without a result" : "") + ", #{result[:minutes]} min" +
        (result[:relaunched].positive? ? " (runner relaunched #{result[:relaunched]}x)" : "") +
        (result[:retired] ? " (simulator retired, kept refusing the runner)" : "") +
        (result[:merged] ? "" : " (result bundles not merged)")
end
all_outcomes = results.map { |result| result[:outcomes] }.reduce({}, :merge)
summary << "total: #{tests.size} tests, #{all_outcomes.values.count(true)} passed, #{all_outcomes.values.count(false)} failed"
summary << "#{unrun} tests never ran, no shard was left to take them" if unrun.positive?
summary.each { |line| say("shards", line) }
write_job_summary(["UITest shards (#{results.size} of #{options[:workers]} requested):", *summary.map { |line| "- #{line}" }])
exit(results.all? { |result| result[:passed] } && unrun.zero? ? 0 : 1)
