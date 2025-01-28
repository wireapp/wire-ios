//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import NeedleFoundation
import WireAPI
import WireDataModel

protocol PullEventsSyncDependency: Dependency {
    var userIdentifier: UUID { get }
}

protocol PullEventsSyncProvider {
    func pullEventsSync(
        selfClientID: String
    ) async -> any PullUpdateEventsSyncProtocol
}

/// Provides sync objects.
final class SyncComponent: Component<PullEventsSyncDependency>, PullEventsSyncProvider {
    private let context: NSManagedObjectContext

    init(
        parent: any Scope,
        context: NSManagedObjectContext
    ) {
        self.context = context
        super.init(parent: parent)
    }

    func pullEventsSync(
        selfClientID: String
    ) async -> any PullUpdateEventsSyncProtocol {
        let apiComponent = APIComponent(
            parent: self,
            selfClientID: selfClientID
        )

        return await PullUpdateEventsSync(
            selfClientID: selfClientID,
            apiProvider: apiComponent,
            storeProvider: localStoreComponent,
            decryptor: updateEventDecryptor
        )
    }

    // MARK: - Private

    private var updateEventDecryptor: any UpdateEventDecryptorProtocol {
        UpdateEventDecryptor(
            proteusMessageDecryptor: proteusMessageDecryptor,
            mlsMessageDecryptor: mlsMessageDecryptor,
            messageLocalStore: localStoreComponent.messageLocalStore
        )
    }

    private var proteusMessageDecryptor: any ProteusMessageDecryptorProtocol {
        ProteusMessageDecryptor(
            proteusService: context.proteusService!,
            userClientsLocalStore: localStoreComponent.userClientsLocalStore,
            userLocalStore: localStoreComponent.userLocalStore
        )
    }

    private var mlsMessageDecryptor: any MLSMessageDecryptorProtocol {
        MLSMessageDecryptor(
            mlsDecryptionService: context.mlsDecryptionService!,
            conversationLocalStore: localStoreComponent.conversationLocalStore
        )
    }

    // MARK: - Child components

    var localStoreComponent: LocalStoreComponent {
        LocalStoreComponent(parent: self, context: NSManagedObjectContext(.mainQueue))
    }

}
