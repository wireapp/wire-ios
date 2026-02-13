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
import WireCrypto
import WireLogging

extension Sequence where Element: NSManagedObject {

    /// Perform changes on a sequence of NSManagedObjects and save at a regular interval and fault
    /// objects in order to keep memory consumption low.
    ///
    /// - Parameters:
    ///   - saveInterval: Number of changes we are performed before the context is saved
    ///   - block: Change which should be performed on the objects
    func modifyAndSaveInBatches(saveInterval: Int = 10_000, _ block: (Element) throws -> Void) throws {
        var processed: [Element] = []

        for element in self {
            try autoreleasepool {
                try block(element)

                processed.append(element)

                if processed.count > saveInterval {
                    let context = element.managedObjectContext

                    try context?.save()
                    processed.forEach {
                        context?.refresh($0, mergeChanges: false)
                    }
                    processed = []
                }
            }
        }

        try processed.last?.managedObjectContext?.save()
    }

}

public extension NSManagedObjectContext {

    var isLocked: Bool {
        earMessageEncryptionService?.isLocked ?? false
    }

    /// Whether the encryption at rest feature is enabled.

    internal(set) var encryptMessagesAtRest: Bool {
        get {
            guard let value = persistentStoreMetadata(
                forKey: PersistentMetadataKey.encryptMessagesAtRest
                    .rawValue
            ) as? NSNumber else {
                return false
            }

            return value.boolValue
        }

        set {
            setPersistentStoreMetadata(
                NSNumber(value: newValue),
                key: PersistentMetadataKey.encryptMessagesAtRest.rawValue
            )
        }

    }

    private static let earMessageEncryptionServiceKey = "earMessageEncryptionServiceKey"

    internal var earMessageEncryptionService: EARMessageEncryptionServiceProtocol? {
        get {
            userInfo[Self.earMessageEncryptionServiceKey] as? EARMessageEncryptionServiceProtocol
        } set {
            userInfo[Self.earMessageEncryptionServiceKey] = newValue
        }
    }

    func getEarMessageEncryptionService() throws -> EARMessageEncryptionServiceProtocol {
        guard let service = earMessageEncryptionService else {
            throw EARError.missingMessageEncryptionService
        }

        return service
    }

    func earContextData() throws -> Data {

        let selfUser = ZMUser.selfUser(in: self)

        guard
            let selfClient = selfUser.selfClient(),
            let selfUserId = selfUser.remoteIdentifier?.transportString(),
            let selfClientId = selfClient.remoteIdentifier,
            let contextData = (selfUserId + selfClientId).data(using: .utf8)
        else {
            WireLogger.ear.error("Could not obtain self user id and self client id")
            assertionFailure("Could not obtain self user id and self client id")
            throw EARError.missingContextData
        }

        return contextData
    }

    enum EARError: LocalizedError {
        case missingMessageEncryptionService
        case missingContextData

        public var errorDescription: String? {
            switch self {
            case .missingMessageEncryptionService:
                "Missing message encryption service"
            case .missingContextData:
                "Missing context data"
            }
        }
    }

}

// MARK: - Migratable

private typealias MigratableEntity = EncryptionAtRestMigratable & ZMManagedObject

/// A type that needs to be migrated when encryption at rest is enabled / disabled.

protocol EncryptionAtRestMigratable {

    /// The predicate to use to fetch specific instances for migration.

    static var predicateForObjectsNeedingMigration: NSPredicate? { get }

    /// Migrate necessary data to adhere to encryption at rest feature.
    ///
    /// For example, encrypt sensitve data and set a nonce.

    func migrateTowardEncryptionAtRest(
        contextData: Data,
        messageEncryptionService: EARMessageEncryptionServiceProtocol
    ) throws

    /// Migrate necessary data to make it available under normal circumstances.
    ///
    /// For example, decrypt sensitive data and clear the nonce.

    func migrateAwayFromEncryptionAtRest(
        contextData: Data,
        messageEncryptionService: EARMessageEncryptionServiceProtocol
    ) throws

}
