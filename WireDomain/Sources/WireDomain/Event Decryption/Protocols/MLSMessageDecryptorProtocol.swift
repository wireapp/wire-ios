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
/// Decrypt MLS messages.
protocol MLSMessageDecryptorProtocol {

    /// Decrypt a MLS message.
    ///
    /// - Parameter eventData: A payload containing the encrypted message.
    /// - Returns: The payload containing the decrypted message.

    func decryptedMessageAddEventData(
        from eventData: ConversationMLSMessageAddEvent,
        context: CoreCryptoContextProtocol?
    ) async throws -> ConversationMLSMessageAddEvent

    /// Decrypt a MLS welcome message
    ///
    /// - Parameter eventData: A payload containing the encrypted welcome message

    func decryptedWelcomeMessageEventData(
        from eventData: ConversationMLSWelcomeEvent,
        context: CoreCryptoContextProtocol?
    ) async throws
}
