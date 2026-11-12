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

require "fileutils"
require "open3"
require "optparse"
require "time"

def credential_values(env_file)
    values = ENV.select { |key, _| key.match?(/PASSWORD|AUTH|TOKEN|SECRET|USERNAME|EMAIL|API.?KEY/) }.values
    if env_file && File.exist?(env_file)
        File.foreach(env_file) do |line|
            match = line.match(/\A\s*([A-Z0-9_]+)\s*=\s*(.+?)\s*\z/)
            values << match[2].delete_prefix('"').delete_suffix('"').gsub("$()", "") if
                match && match[1].match?(/PASSWORD|AUTH|TOKEN|SECRET|USERNAME|EMAIL|API.?KEY/)
        end
    end
    values.select { |value| value.length >= 4 }.uniq.sort_by { |value| -value.bytesize }.map(&:b)
end

def sanitize_output(text, secrets)
    text = text.dup
    secrets.each { |secret| text = text.gsub(secret, "***") }
    text = text.force_encoding("UTF-8").scrub
    # These values are generated during tests and are not in env.xcconfig.
    text = text.gsub(/(login: email ).*?( and password )[^\r\n]*/i, '\1***\2***')
    text = text.gsub(/(\bType (?:text )?)(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')/, '\1"***"')
    text = text.gsub(/(\bpassword["']?\s*[:=]\s*)(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[^\s,;}]+)/i, '\1***')
    text.gsub(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i, "***")
end

def signal_group(signal, group)
    Process.kill(signal, group)
rescue Errno::ESRCH
    nil
end

def command_groups(pid)
    # Fastlane's PTY commands and Simulator setup can start their own process groups.
    output, status = Open3.capture2("ps", "-axo", "pid=,ppid=,pgid=")
    return [pid] unless status.success?

    processes = output.lines.map { |line| line.split.map(&:to_i) }
    descendants = { pid => true }
    loop do
        count = descendants.size
        processes.each { |child, parent, _| descendants[child] = true if descendants[parent] }
        break if descendants.size == count
    end
    groups = processes.filter_map { |child, _, group| group if descendants[child] }
    (groups + [pid]).uniq.select { |group| group.positive? && group != Process.getpgrp }
end

def stop_command(wait_thread, signal = "TERM")
    groups = command_groups(wait_thread.pid).map { |group| -group }
    groups.each { |group| signal_group(signal, group) }
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    while groups.any? { |group| signal_group(0, group) } &&
          Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
        sleep(0.05)
    end
    groups.each { |group| signal_group("KILL", group) }
    wait_thread.join(5)
end

options = {}
OptionParser.new do |parser|
    parser.banner = "Usage: run_ui_tests_with_timeout.rb --timeout-seconds N --log PATH [--redact-env-file PATH] -- COMMAND"
    parser.on("--timeout-seconds N", Float) { |value| options[:timeout] = value }
    parser.on("--log PATH") { |value| options[:log] = value }
    parser.on("--redact-env-file PATH") { |value| options[:env_file] = value }
end.parse!
abort("A positive timeout, log path and command are required") unless
    options[:timeout]&.finite? && options[:timeout].positive? && options[:log] && !ARGV.empty?

secrets = credential_values(options[:env_file])
FileUtils.mkdir_p(File.dirname(options[:log]))
$stdout.sync = true
status = File.open(options[:log], "w") do |log|
    log.sync = true
    emit = lambda do |text|
        safe = sanitize_output(text, secrets)
        log.write(safe)
        $stdout.write(safe)
    end
    pending = +"".b
    timed_out = false
    cancelled = nil
    # Record signals before spawning. The read loop handles cancellation without interrupting cleanup.
    previous_signals = %w[INT TERM].to_h do |name|
        [name, Signal.trap(name) { cancelled = Signal.list.fetch(name) }]
    end
    begin
        emit.call("[ui-tests] Started #{Time.now.utc.iso8601}; timeout #{format('%g', options[:timeout])}s\n")
        result = Open3.popen2e(*ARGV, pgroup: true) do |input, output, wait_thread|
            input.close
            output.binmode
            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + options[:timeout]
            readers = [output]
            begin
                loop do
                    remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
                    break 128 + cancelled if cancelled
                    if remaining <= 0
                        timed_out = true
                        break 124
                    end
                    if readers.empty? && !wait_thread.alive?
                        child_status = wait_thread.value
                        break child_status.exitstatus || 128 + child_status.termsig
                    end
                    next unless IO.select(readers, nil, nil, [remaining, 0.2].min)

                    chunk = output.read_nonblock(16_384, exception: false)
                    if chunk.nil?
                        readers.clear
                    elsif chunk != :wait_readable
                        pending << chunk
                        while (newline = pending.index("\n"))
                            emit.call(pending.slice!(0, newline + 1))
                        end
                    end
                end
            ensure
                stop_command(wait_thread, cancelled || "TERM") if wait_thread.alive?
                output.close
            end
        end
        result = 128 + cancelled if cancelled
    ensure
        previous_signals.each { |name, handler| Signal.trap(name, handler) }
    end
    unless pending.empty?
        emit.call(pending)
        emit.call("\n") unless pending.end_with?("\n")
    end
    reason = cancelled ? "Cancelled" : (timed_out ? "Timed out" : "Finished")
    emit.call("[ui-tests] #{reason} #{Time.now.utc.iso8601}; exit #{result}\n")
    result
end
exit(status)
