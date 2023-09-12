////
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

extension ZMUser {

    @objc
    public static let supportedProtocolsKey = "supportedProtocols"

    @NSManaged
    private var primitiveSupportedProtocols: [Int16]?

    /// The messaging protocols that this user can communicate with.

    public var supportedProtocols: Set<MessageProtocol> {
        get {
            willAccessValue(forKey: Self.supportedProtocolsKey)
            let result = primitiveSupportedProtocols ?? []
            didAccessValue(forKey: Self.supportedProtocolsKey)
            return Set(result.compactMap(MessageProtocol.init))
        }

        set {
            let currentValue = supportedProtocols
            guard newValue != currentValue else { return }

            // We can't drop support for MLS once we've adopted it.
            if currentValue.contains(.mls) && !newValue.contains(.mls) {
                return
            }

            willChangeValue(forKey: Self.supportedProtocolsKey)
            primitiveSupportedProtocols = newValue.map(\.rawValue)
            didChangeValue(forKey: Self.supportedProtocolsKey)
            setLocallyModifiedKeys([Self.supportedProtocolsKey])
        }
    }

}
