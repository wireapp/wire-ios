//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import Foundation
import WireLogging

public enum Process {

    /// Registers an expiring activity with the system to give the process extra time when entering the background.
    ///
    /// The activity ends either:
    /// - when the system is about to suspend the process
    /// - when the specified timeout is reached
    /// - when the returned `Cancellable` is cancelled
    ///
    /// - warning: This method is unsafe as it depends on a semaphore to block the process until the activity expires.
    /// A limited number of concurrent expiring activities can be registered after which thread explosion is reached
    /// and deadlocks can occur. Avoid using this method within main app as there are better alternatives.
    public static func registerUnsafeExpiringActivity(
        _ reason: String,
        timeout: DispatchWallTime,
        processInfo: ProcessInfo = .processInfo,
    ) -> Cancellable {
        let semaphore = DispatchSemaphore(value: 0)

        processInfo.performExpiringActivity(withReason: reason) { isExpired in
            if isExpired {
                WireLogger.backgroundActivity.debug("Expiring activity will expire: \(reason)")
                semaphore.signal()
            } else {
                WireLogger.backgroundActivity.debug("Expiring activity will start: \(reason)")
                _ = semaphore.wait(wallTimeout: timeout)
                WireLogger.backgroundActivity.debug("Expiring activity did end: \(reason)")
            }
        }

        return AnyCancellable {
            semaphore.signal()
        }
    }

}
