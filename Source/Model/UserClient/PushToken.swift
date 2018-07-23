////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public struct PushToken: Equatable, Codable {
    public let deviceToken: Data
    public let appIdentifier: String
    public let transportType: String
    public var isRegistered: Bool
    public var isMarkedForDeletion: Bool = false
    public var isMarkedForDownload: Bool = false
}

extension PushToken {

    public init(deviceToken: Data, appIdentifier: String, transportType: String, isRegistered: Bool) {
        self.init(deviceToken: deviceToken, appIdentifier: appIdentifier, transportType: transportType, isRegistered: isRegistered, isMarkedForDeletion: false, isMarkedForDownload: false)
    }

    public var deviceTokenString: String {
        return deviceToken.zmHexEncodedString()
    }

    public func resetFlags() -> PushToken {
        var token = self
        token.isMarkedForDownload = false
        token.isMarkedForDeletion = false
        return token
    }

    public func markToDownload() -> PushToken {
        var token = self
        token.isMarkedForDownload = true
        return token
    }

    public func markToDelete() -> PushToken {
        var token = self
        token.isMarkedForDeletion = true
        return token
    }

}
