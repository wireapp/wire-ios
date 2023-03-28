//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public enum DeveloperFlag: String, CaseIterable {

    public static var storage = UserDefaults.standard

    case showCreateMLSGroupToggle
    case nseV2
    case deprecatedCallingUI

    public var description: String {
        switch self {
        case .showCreateMLSGroupToggle:
            return "Turn on to show the MLS toggle when creating a new group."

        case .nseV2:
            return "Turn on to use the new implementation of the notification service extension."

        case .deprecatedCallingUI:
            return "Turn on to use deprecated calling UI"

        }
    }

    public var isOn: Bool {
        get { return Self.storage.bool(forKey: rawValue) }
        set { Self.storage.set(newValue, forKey: rawValue) }
    }

    static public func clearAllFlags() {
        allCases.forEach {
            storage.set(nil, forKey: $0.rawValue)
        }
    }

}
