//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@objc
public enum ChannelAccessLevelPermission: Int {
    case everybody
    case admins
}

extension ZMConversation: HasChannelAccessLevelPermission {

    /// The underlying string value of the private channel permission.

    @NSManaged private var privateChannelPermissionValue: String?
    
    public var accessLevelPermissions: ChannelAccessLevelPermission? {
        get {
            guard conversationType == .group else { return nil }

            switch privateChannelPermissionValue {
            case "admins": return .admins
            case "everybody": return .everybody
            default: return nil
            }
        }
        set {
            privateChannelPermissionValue = switch newValue {
            case .admins: "admins"
            case .everybody: "everybody"
            case nil: nil
            }
        }
    }
}

public protocol HasChannelAccessLevelPermission {

    var accessLevelPermissions: ChannelAccessLevelPermission? { get }

}
