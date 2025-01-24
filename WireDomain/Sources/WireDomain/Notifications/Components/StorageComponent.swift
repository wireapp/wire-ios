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
import WireLogging
import WireAPI
import WireFoundation
import WireCrypto

protocol StorageDependency: Dependency {
    var selectedAccount: Account { get }
    var applicationContainer: URL { get }
    var applicationIdentifier: String { get }
    var userIdentifier: UUID { get }
}

class StorageComponent: Component<StorageDependency> {
    
    override init(parent: any Scope) {
        super.init(parent: parent)
        
        coreData.loadStores { error in
            if let error {
                WireLogger.notifications.error(
                    "Loading coreDataStack with error: \(error.localizedDescription)"
                )
            }
        }
        
        coreData.syncContext.performAndWait {
            if DeveloperFlag.proteusViaCoreCrypto.isOn { // do we need this ?
                coreData.syncContext.proteusService = proteusService
            }
            
            let mlsFeature = featureRepository.fetchMLS()
            
            if mlsFeature.isEnabled {
                coreData.syncContext.mlsDecryptionService = mlsDecryptionService
            }
        }
    }
    
    var coreData: CoreDataStack {
        let coreData = CoreDataStack(
            account: dependency.selectedAccount,
            applicationContainer: dependency.applicationContainer
        )
        
        return coreData
    }
    
    var cookieStorage: any CookieStorageProtocol {
        CookieStorage(
            userID: dependency.userIdentifier,
            cookieEncryptionKey: cookiesEncryptionKey,
            keychain: keychain
        )
    }
    
    var userDefaults: UserDefaults {
        let userDefaults = UserDefaults.standard
        userDefaults.addSuite(named: dependency.applicationIdentifier)
        return userDefaults
    }
    
    // MARK: - Private
    
    private var keychain: any KeychainProtocol {
        Keychain()
    }
    
    private var proteusService: any ProteusServiceInterface {
        ProteusService(
            coreCryptoProvider: coreCryptoProvider
        )
    }
    
    private var mlsDecryptionService: any MLSDecryptionServiceInterface {
        MLSDecryptionService(
            context: coreData.syncContext,
            mlsActionExecutor: mlsActionExecutor
        )
    }
    
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
    
    private var accountContainer: URL {
        CoreDataStack.accountDataFolder(
            accountIdentifier: dependency.userIdentifier,
            applicationContainer: dependency.applicationContainer
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
    
    private var featureRepository: any FeatureRepositoryInterface {
        FeatureRepository(context: coreData.syncContext)
    }
    
    private var cookiesEncryptionKey: Data {
        let cookieKey = "ZMCookieKey"
        let sharedDefaults = UserDefaults.standard
        if let key = sharedDefaults.data(forKey: "cookieKeyKey") {
            return key
        }
        
        // On older versions, the key might have been stored in standard user defaults.
        // Check there first, then migrate it to shared defaults.
        if let key = UserDefaults.standard.data(forKey: cookieKey) {
            UserDefaults.standard.removeObject(forKey: cookieKey)
            sharedDefaults.set(key, forKey: cookieKey)
            return key
        }
        
        // Create a new key
        do {
            var newKey = try AES256Crypto.generateRandomEncryptionKey()
            sharedDefaults.set(newKey, forKey: cookieKey)
            return newKey
        } catch {
            fatalError()
        }
    }
    
}
