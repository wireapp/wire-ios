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

public class TestUserDefaults: UserDefaults {
    private let suiteName: String

    public var shouldSet: (_ value: Any?, _ key: String) -> Bool = { _, _ in true }

    public override init?(suiteName suitename: String?) {
        self.suiteName = suitename ?? ""
        super.init(suiteName: suitename)
    }

    public override func set(_ value: Any?, forKey defaultName: String) {
        if shouldSet(value, defaultName) {
            super.set(value, forKey: defaultName)
        }
    }

    public func reset() {
        removePersistentDomain(forName: suiteName)
    }
}
