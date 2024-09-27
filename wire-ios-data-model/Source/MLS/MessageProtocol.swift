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

// MARK: - MessageProtocol

/// Protocols for exchanging end-to-end-encrypted messages
/// between clients.

public enum MessageProtocol: String, CaseIterable {
    /// With proteus, inidividual encryption sessions are created between
    /// every pair of clients in a conversation. This imposes constraints on
    /// number of participants in a conversation because the number of
    /// encrypted payloads sent per message increases exponentionally as
    /// the number of partipants grows linerarly.

    case proteus

    /// With mls, a shared cryptographic state is maintained and shared between
    /// all participants in a group, so only a single encrypted payload is required
    /// per message. This allows for much larger groups compared to proteus.

    case mls

    /// Conversations with the mixed message protocol are in the state of migrating from
    /// proteus to mls. Message encryption is done using the proteus protocol,
    /// while other operations (such as adding / removing participants) are reflected on the underlying mls group.
    /// Calling is still done the proteus way until the migration is finalised

    case mixed
}

// MARK: MessageProtocol + int16Value

extension MessageProtocol {
    var int16Value: Int16 {
        let index = Self.allCases.firstIndex(of: self)!
        return .init(index)
    }

    init?(int16Value: Int16) {
        guard Self.allCases.indices.contains(.init(int16Value)) else { return nil }
        self = Self.allCases[.init(int16Value)]
    }
}

// MARK: CustomStringConvertible

extension MessageProtocol: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
