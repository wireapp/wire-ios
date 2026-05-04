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

import Foundation
import WireLogging
import WireNetwork

// sourcery: AutoMockable
public protocol PushSupportedProtocolsSyncProtocol {

    func push(supportedProtocols: Set<WireNetwork.MessageProtocol>) async throws

}

/// An object to update the supported protocols of the
/// self user both locally and remotely.

public struct PushSupportedProtocolsSync: PushSupportedProtocolsSyncProtocol {

    private let api: any SelfUserAPI
    private let store: any UserLocalStoreProtocol

    public init(
        api: any SelfUserAPI,
        store: any UserLocalStoreProtocol
    ) {
        self.api = api
        self.store = store
    }

    /// Update the supported protocols remotely then update locally.

    public func push(supportedProtocols: Set<WireNetwork.MessageProtocol>) async throws {
        var supportedProtocols = supportedProtocols

        do {
            try await api.pushSupportedProtocols(supportedProtocols)
        } catch let SelfUserAPIError.mlsProtocolError(errorMessage) {
            WireLogger.supportedProtocols
                .warn(
                    "Failed to push supported protocols: \(errorMessage), fallback to adding mls",
                    attributes: .safePublic
                )

            supportedProtocols.insert(.mls)
            try await api.pushSupportedProtocols(supportedProtocols)
        }

        await store.updateSelfUserSupportedProtocols(supportedProtocols: supportedProtocols.toDomainModel())
    }

}
