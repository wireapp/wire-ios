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

import Foundation

final class MockAppLock: AppLockType {
    // MARK: - Types

    struct MethodCalls {
        var beginTimer: [Void] = []
    }

    // MARK: - Metrics

    var methodCalls = MethodCalls()

    // MARK: - Properties

    weak var delegate: AppLockDelegate?

    var isAvailable = true
    var isActive = true
    var isForced = false
    var timeout: UInt = 5
    var isLocked = false
    var requireCustomPasscode = false
    var isCustomPasscodeSet = false
    var needsToNotifyUser = false

    // MARK: - Methods

    func deletePasscode() throws {
        // No op
    }

    func updatePasscode(_: String) throws {
        // No op
    }

    func beginTimer() {
        methodCalls.beginTimer.append(())
    }

    func open() throws {
        // No op
    }

    func evaluateAuthentication(
        passcodePreference: AppLockPasscodePreference,
        description: String,
        callback: @escaping (AppLockAuthenticationResult) -> Void
    ) {
        fatalError("Not implemented")
    }

    func evaluateAuthentication(customPasscode: String) -> AppLockAuthenticationResult {
        fatalError("Not implemented")
    }
}
