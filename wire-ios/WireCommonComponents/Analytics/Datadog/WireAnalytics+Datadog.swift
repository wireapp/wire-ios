//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import WireAnalytics
import WireSystem

#if canImport(WireDatadog)
    import WireDatadog
#endif

extension WireAnalytics {
    /// Namespace for Datadog analytics.
    public enum Datadog {
        private static let shared: (any WireDatadogProtocol & LoggerProtocol)? = {
            #if canImport(WireDatadog)
                let builder = WireDatadogBuilder()
                return builder.build()
            #else
                return nil
            #endif
        }()

        /// SHA256 string to identify current device across app and extensions.
        public static var userIdentifier: String? {
            shared?.userIdentifier
        }

        /// Enables Datadog analytics instance if available and makes it a global logger. If Datadog is not available,
        /// the function just returns.
        /// - Note: this should be called early and **has effect only once**
        public static func enable() {
            enableOnlyOnce.execute()
        }

        static var enableOnlyOnce = OnceOnlyThreadSafeFunction {
            guard let shared else { return }

            shared.enable()
            WireLogger.addLogger(shared)

            // pass tags to DataDog through WireLogger
            WireLogger.system.addTag(.processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
            WireLogger.system.addTag(.processName, value: ProcessInfo.processInfo.processName)
        }
    }
}

/// Wrapper class to execute a function just once, thread safe
class OnceOnlyThreadSafeFunction {
    private let lock = NSLock()
    private var executed = false
    private let function: () -> Void

    init(_ function: @escaping () -> Void) {
        self.function = function
    }

    func execute() {
        lock.lock()
        defer { lock.unlock() }

        if !executed {
            executed = true
            function()
        }
    }
}
