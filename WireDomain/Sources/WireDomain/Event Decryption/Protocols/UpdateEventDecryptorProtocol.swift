//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireCoreCrypto
import WireNetwork

// sourcery: AutoMockable
/// Decrypt the E2EE content within update events.
public protocol UpdateEventDecryptorProtocol {

    /// Decrypt events in the given event envelope.
    ///
    /// - Parameter eventEnvelope: An event envelope that contains events received from the server.
    /// - Returns: A list of decrypted update events.

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope, context: CoreCryptoContextProtocol?) async
        -> EventDecryptorResult

}

public struct EventDecryptorResult {

    let events: [UpdateEvent]
    let brokenMLSGroupIDs: Set<String>

}
