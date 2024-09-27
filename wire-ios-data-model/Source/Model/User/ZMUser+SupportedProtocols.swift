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

extension ZMUser {
    @objc public static let supportedProtocolsKey = "supportedProtocols"

    @NSManaged private var primitiveSupportedProtocols: [Int16]?

    /// Objc-C helper method because enum 'MessageProtocol' is not available.
    @objc(setSupportedProtocols:)
    func _setSupportedProtocols(_ protocols: Set<String>) {
        supportedProtocols = Set(protocols.compactMap {
            guard let messageProtocol = MessageProtocol(rawValue: $0) else {
                assertionFailure("can not map value \($0) as MessageProtocol!")
                return nil
            }
            return messageProtocol
        })
    }

    /// The messaging protocols that this user can communicate with.
    public var supportedProtocols: Set<MessageProtocol> {
        get {
            willAccessValue(forKey: Self.supportedProtocolsKey)
            let result = primitiveSupportedProtocols ?? []
            didAccessValue(forKey: Self.supportedProtocolsKey)
            return Set(result.compactMap(MessageProtocol.init(int16Value:)))
        }

        set {
            let currentValue = supportedProtocols
            guard newValue != currentValue else {
                return
            }

            // We can't drop support for MLS once we've adopted it.
            if currentValue.contains(.mls), !newValue.contains(.mls) {
                return
            }

            willChangeValue(forKey: Self.supportedProtocolsKey)
            primitiveSupportedProtocols = newValue.map(\.int16Value)
            didChangeValue(forKey: Self.supportedProtocolsKey)

            if isSelfUser {
                setLocallyModifiedKeys([Self.supportedProtocolsKey])
            }
        }
    }
}
