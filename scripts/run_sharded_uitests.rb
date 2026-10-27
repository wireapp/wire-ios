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

# Runs UI tests in shards, one simulator per shard, instead of Xcode's parallel testing.

# serial. Here every simulator is created, seeded and proven to launch an app before any test starts, the app is
# built once with `build-for-testing`, and each shard runs its own `xcodebuild test-without-building`.
#
# Exit status: 0 when every shard passed, 1 otherwise.

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

# Xcode prints the test runner's environment, credentials included, when a launch fails. The raw logs stay in
# the log directory; this writes a copy with those values replaced, which is what CI uploads.
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

# Keeps every test of a class in one shard and fills the least loaded shard with the largest class first.
def balance(identifiers, count)
    classes = identifiers.group_by { |identifier| identifier.split("/")[0..1].join("/") }
    shards = Array.new([count, classes.size].min) { [] }
    classes.values.sort_by { |tests| -tests.size }.each do |tests|
        shards.min_by(&:size).concat(tests)
    end
    shards.reject(&:empty?)
end

# A booted simulator can still refuse app launches while SpringBoard finishes starting up, which is exactly how
# Xcode's runner launch fails. Launching a system app is the same check, so wait until it works.
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
    run("xcrun", "simctl", "boot", udid, timeout: 120) # fails harmlessly when already booted
    run!("xcrun", "simctl", "bootstatus", udid, "-b", timeout: 600)
    run!("bash", File.join(ROOT, "scripts/seed-simulator-media.sh"), env: { "IOS_SIM_ID" => udid }, timeout: 600)
    wait_until_launchable(udid)
end

Dir.chdir(ROOT)
tests = File.readlines(options[:tests_file]).map(&:strip).reject(&:empty?).uniq
abort("No tests to run in #{options[:tests_file]}") if tests.empty?

planned = balance(tests, options[:workers])
say("shards", "#{tests.size} tests in #{planned.size} shards: #{planned.map(&:size).join(', ')} tests")
FileUtils.mkdir_p([options[:log_dir], options[:result_dir], File.dirname(options[:simulators_file])])

# Extra simulators are created and seeded while the app builds.
simulators_lock = Mutex.new
preparations = [Thread.new do
    wait_until_launchable(options[:base_simulator])
    options[:base_simulator]
end]
(2..planned.size).each do |index|
    preparations << Thread.new do
        name = "#{options[:base_simulator]}-shard-#{index}"
        udid = run!("xcrun", "simctl", "create", name, options[:device_type], options[:runtime]).strip
        simulators_lock.synchronize { File.open(options[:simulators_file], "a") { |file| file.puts(udid) } }
        prepare_simulator(udid)
        udid
    end
end
preparations.each { |thread| thread.report_on_exception = false }

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

simulators = preparations.each_with_index.filter_map do |thread, index|
    thread.value
rescue => error
    say("shards", "simulator for shard #{index + 1} is not usable, continuing without it: #{error.message}")
    nil
end

unless built
    say("shards", "build-for-testing failed, no tests were run")
    exit(1)
end

if simulators.empty?
    say("shards", "no simulator accepted an app launch, no tests were run")
    exit(1)
end

xctestrun = Dir.glob(File.join(options[:derived_data], "Build/Products", "#{options[:scheme]}_#{options[:test_plan]}_*.xctestrun")).max_by { |path| File.mtime(path) }
abort("[shards] no .xctestrun for #{options[:scheme]}/#{options[:test_plan]} in #{options[:derived_data]}") if xctestrun.nil?

shards = simulators.size == planned.size ? planned : balance(tests, simulators.size)
if shards.size < planned.size
    # A green run must not hide that the requested parallelism did not happen.
    message = "Only #{simulators.size} of #{planned.size} simulators were ready, running #{shards.size} shards instead of #{planned.size}"
    say("shards", message)
    write_job_summary("> [!WARNING]\n> UITest shards: #{message}")
end

# The runner can still be refused on a simulator that just opened Settings fine; such a shard ran no test, so
# running it once more costs little.
RUNNER_LAUNCH_FAILURE = /Failed to install or launch the test runner|Application failed preflight checks/.freeze
TEST_STARTED = /Test Case '.*' started/.freeze

results = shards.each_with_index.map do |shard_tests, index|
    number = index + 1
    Thread.new do
        label = "shard #{number}"
        shard_dir = File.join(options[:result_dir], "shard-#{number}")
        result_bundle = File.join(shard_dir, "#{options[:scheme]}.xcresult")
        log_path = File.join(options[:log_dir], "#{options[:scheme]}-shard-#{number}.log")
        FileUtils.rm_rf(result_bundle)
        FileUtils.mkdir_p(shard_dir)

        command = [
            "xcodebuild", "test-without-building",
            "-xctestrun", xctestrun,
            "-destination", "platform=iOS Simulator,id=#{simulators[index]}",
            "-derivedDataPath", File.join(options[:log_dir], "shard-#{number}-DerivedData"),
            "-resultBundlePath", result_bundle,
            "-collect-test-diagnostics", "never",
            "-parallel-testing-enabled", "NO"
        ]
        command += ["-retry-tests-on-failure", "-test-iterations", options[:test_iterations].to_s] if options[:test_iterations] > 1
        command += shard_tests.map { |identifier| "-only-testing:#{identifier}" }

        started = Time.now
        say(label, "#{shard_tests.size} tests on simulator #{simulators[index]}")
        passed = stream(label, command, log_path)
        log = File.exist?(log_path) ? File.read(log_path, encoding: "UTF-8", invalid: :replace) : ""
        relaunched = !passed && log.match?(RUNNER_LAUNCH_FAILURE) && !log.match?(TEST_STARTED)
        if relaunched
            say(label, "test runner did not launch and no test ran, running this shard once more")
            # Keep the first attempt for debugging, outside the results directory so reports ignore it.
            # A result bundle is a directory: moving it onto an earlier run's copy would nest it inside, so replace that copy.
            first_log = log_path.sub(/\.log\z/, "-attempt-1.log")
            first_bundle = File.join(options[:log_dir], "#{options[:scheme]}-shard-#{number}-attempt-1.xcresult")
            FileUtils.rm_rf([first_log, first_bundle])
            FileUtils.mv(log_path, first_log)
            FileUtils.mv(result_bundle, first_bundle) if File.exist?(result_bundle)
            publish_log(first_log, options[:published_log_dir], secrets)
            begin
                wait_until_launchable(simulators[index])
            rescue => error
                say(label, error.message)
            end
            passed = stream(label, command, log_path)
        end
        publish_log(log_path, options[:published_log_dir], secrets)
        { number: number, tests: shard_tests.size, passed: passed, relaunched: relaunched, minutes: ((Time.now - started) / 60).round(1) }
    end
end.map(&:value)

summary = results.map do |result|
    "shard #{result[:number]}: #{result[:passed] ? 'passed' : 'FAILED'}, #{result[:tests]} tests, #{result[:minutes]} min" +
        (result[:relaunched] ? " (runner relaunched once)" : "")
end
summary.each { |line| say("shards", line) }
write_job_summary(["UITest shards (#{results.size} of #{options[:workers]} requested):", *summary.map { |line| "- #{line}" }])
exit(results.all? { |result| result[:passed] } ? 0 : 1)
