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
import WireDataModel
import WireAPI

protocol PullEventsSyncDependency: Dependency {
    var userClientsLocalStore: UserClientsLocalStoreProtocol { get }
    var context: NSManagedObjectContext { get }
    var userIdentifier: UUID { get }
}

class PullEventsSyncComponent: Component<PullEventsSyncDependency> {
    let selfClientID: String
    
    init(parent: any Scope, selfClientID: String) {
        self.selfClientID = selfClientID
        super.init(parent: parent)
    }
    
    var updateEventDecryptor: UpdateEventDecryptorProtocol {
        UpdateEventDecryptor(
            proteusMessageDecryptor: proteusMessageDecryptor,
            mlsMessageDecryptor: mlsMessageDecryptor,
            messageLocalStore: localStoreComponent.messageLocalStore
        )
    }
    
    var proteusMessageDecryptor: ProteusMessageDecryptor {
        ProteusMessageDecryptor(
            proteusService: dependency.context.proteusService!,
            userClientsLocalStore: dependency.userClientsLocalStore,
            userLocalStore: localStoreComponent.userLocalStore
        )
    }
    
    var mlsMessageDecryptor: any MLSMessageDecryptorProtocol {
        MLSMessageDecryptor(
            mlsDecryptionService: dependency.context.mlsDecryptionService!,
            mlsService: dependency.context.mlsService!,
            conversationLocalStore: localStoreComponent.conversationLocalStore
        )
    }

    var pullUpdateEventsSync: PullUpdateEventsSyncProtocol {
        get async {
            await PullUpdateEventsSync(
                selfClientID: selfClientID,
                api: apiComponent.updateEventsAPI,
                store: localStoreComponent.updateEventsLocalStore,
                decryptor: updateEventDecryptor
            )
        }
    }
    
    // MARK: - Private
    
    private var apiComponent: APIComponent {
        APIComponent(parent: self)
    }
    
    private var localStoreComponent: LocalStoreComponent {
        LocalStoreComponent(parent: self)
    }
    
}
