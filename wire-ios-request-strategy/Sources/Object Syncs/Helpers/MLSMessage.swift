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

/// A message that can be sent in an mls group.

public protocol MLSMessage: OTREntity, MLSEncryptedPayloadGenerator, Hashable {}

extension ZMClientMessage: MLSMessage {}

extension ZMAssetClientMessage: MLSMessage {}

extension GenericMessageEntity: MLSMessage {

    public func encryptForTransport(using encrypt: (Data) throws -> Data) throws -> Data {
        return try message.encryptForTransport(using: encrypt)
    }

}
