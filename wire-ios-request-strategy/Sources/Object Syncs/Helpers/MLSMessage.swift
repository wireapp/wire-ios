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

/// A message that can be sent in an mls group.

public protocol MLSMessage: OTREntity, MLSEncryptedPayloadGenerator {

    /// Messages can expire, e.g. if network conditions are too slow to send.
    var shouldExpire: Bool { get }

    /// Sets the expiration date with the default time interval.
    func setExpirationDate()
}

extension ZMClientMessage: MLSMessage {}

extension ZMAssetClientMessage: MLSMessage {}

extension GenericMessageEntity: MLSMessage {

    // Just required for protocol conformance.
    public var shouldExpire: Bool { false }

    public func encryptForTransport(using encrypt: (Data) async throws -> Data) async throws -> Data {
        try await message.encryptForTransport(using: encrypt)
    }

    public func setExpirationDate() {
        // Just required for protocol conformance.
        // Generic messages are used as underlying messages in proteus and mls,
        // so they don't need to have their own expiration date.
    }
}
