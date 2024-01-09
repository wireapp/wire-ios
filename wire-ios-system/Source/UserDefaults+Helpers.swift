//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

extension UserDefaults {

    @objc
    public static func random() -> UserDefaults? {
        .init(suiteName: UUID().uuidString)
    }

    @objc
    public func reset() {
        for key in dictionaryRepresentation().keys {
            removeObject(forKey: key)
        }

        synchronize()
    }

    /// Creates an instance with a random (UUID string based) `suiteName`.
    /// When the instance is deallocated, the storage is cleaned up.
    public static func temporary() -> Self {
        let suiteName = UUID().uuidString
        let userDefaults = Self(suiteName: suiteName)!
        objc_setAssociatedObject(
            userDefaults,
            &SuiteCleanUpHandle,
            SuiteCleanUp(suiteName),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return userDefaults
    }
}

// MARK: UserDefaults.temporary() helpers

private final class SuiteCleanUp {

    var suiteName: String

    init(_ suiteName: String) {
        self.suiteName = suiteName
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}

private var SuiteCleanUpHandle = 0
