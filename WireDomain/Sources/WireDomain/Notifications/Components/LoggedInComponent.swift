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

import Foundation
import NeedleFoundation

protocol LoggedInSessionProvider {
    var loggedInSession: LoggedInSessionProtocol { get }
}

/// Provides an authenticated session with injected components.
final class LoggedInComponent: Component<EmptyDependency>, LoggedInSessionProvider {

    var loggedInSession: LoggedInSessionProtocol {
        LoggedInSession(
            coreDataProvider: coreStorageComponent,
            coreServiceProvider: coreServiceComponent,
            localStoresProvider: localStoreComponent,
            pullEventsSyncProvider: syncComponent
        )
    }

    // MARK: - Child components

    var syncComponent: SyncComponent {
        SyncComponent(
            parent: self,
            context: coreStorageComponent.coreData.syncContext,
            proteusService: coreServiceComponent.proteusService,
            mlsDecryptionService: coreServiceComponent.mlsDecryptionService
        )
    }

    var coreStorageComponent: CoreStorageComponent {
        CoreStorageComponent(parent: self)
    }

    var coreServiceComponent: CoreServiceComponent {
        CoreServiceComponent(
            parent: self,
            coreData: coreStorageComponent.coreData
        )
    }

    var localStoreComponent: LocalStoreComponent {
        LocalStoreComponent(
            parent: self,
            context: coreStorageComponent.coreData.syncContext
        )
    }
}
