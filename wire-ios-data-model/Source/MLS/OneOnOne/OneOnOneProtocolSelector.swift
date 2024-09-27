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

// MARK: - OneOnOneProtocolSelectorInterface

// sourcery: AutoMockable
public protocol OneOnOneProtocolSelectorInterface {
    func getProtocolForUser(
        with id: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MessageProtocol?
}

// MARK: - OneOnOneProtocolSelectorError

public enum OneOnOneProtocolSelectorError: Error {
    case userNotFound
}

// MARK: - OneOnOneProtocolSelector

public final class OneOnOneProtocolSelector: OneOnOneProtocolSelectorInterface {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public func getProtocolForUser(
        with id: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MessageProtocol? {
        let commonProtocols = try await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            let selfProtocols = selfUser.supportedProtocols

            guard let otherUser = ZMUser.fetch(with: id, in: context) else {
                throw OneOnOneProtocolSelectorError.userNotFound
            }

            var otherProtocols = otherUser.supportedProtocols

            if otherProtocols.isEmpty {
                // If other users haven't pushed their supported protocols yet,
                // (maybe because they're on old versions of the app), then we
                // assume they support proteus.
                otherProtocols.insert(.proteus)
            }

            return selfProtocols.intersection(otherProtocols)
        }

        if commonProtocols.contains(.mls) {
            return .mls
        } else if commonProtocols.contains(.proteus) {
            return .proteus
        } else {
            return nil
        }
    }
}
