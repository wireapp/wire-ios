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

protocol CoreServiceDependency: Dependency {
    var userIdentifier: UUID { get }
    var applicationContainer: URL { get }
    var applicationIdentifier: String { get }
}

protocol CoreServiceProvider {
    var proteusService: any ProteusServiceInterface { get }
    var mlsDecryptionService: any MLSDecryptionServiceInterface { get }
    var featureRepository: any FeatureRepositoryInterface { get }
}

/// Provides core services.
final class CoreServiceComponent: Component<CoreServiceDependency>, CoreServiceProvider {
    private let coreData: CoreDataStack

    init(
        parent: any Scope,
        coreData: CoreDataStack
    ) {
        self.coreData = coreData
        super.init(parent: parent)
    }

    var proteusService: any ProteusServiceInterface {
        ProteusService(
            coreCryptoProvider: coreCryptoProvider
        )
    }

    var mlsDecryptionService: any MLSDecryptionServiceInterface {
        MLSDecryptionService(
            context: coreData.syncContext,
            mlsActionExecutor: mlsActionExecutor
        )
    }

    var featureRepository: any FeatureRepositoryInterface {
        FeatureRepository(context: coreData.syncContext)
    }

    // MARK: - Private

    private var coreCryptoProvider: any CoreCryptoProviderProtocol {
        CoreCryptoProvider(
            selfUserID: dependency.userIdentifier,
            sharedContainerURL: dependency.applicationContainer,
            accountDirectory: accountContainer,
            syncContext: coreData.syncContext,
            cryptoboxMigrationManager: CryptoboxMigrationManager(),
            allowCreation: false
        )
    }

    private var commitSender: any CommitSending {
        CommitSender(
            coreCryptoProvider: coreCryptoProvider,
            notificationContext: coreData.syncContext.notificationContext
        )
    }

    private var mlsActionExecutor: any MLSActionExecutorProtocol {
        MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            commitSender: commitSender,
            featureRepository: featureRepository
        )
    }

    private var accountContainer: URL {
        CoreDataStack.accountDataFolder(
            accountIdentifier: dependency.userIdentifier,
            applicationContainer: dependency.applicationContainer
        )
    }

}
