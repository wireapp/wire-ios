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
import LocalAuthentication
import WireDataModel

public protocol UserSessionEncryptionAtRestInterface {
    var encryptMessagesAtRest: Bool { get }
    var isDatabaseLocked: Bool { get }

    func setEncryptionAtRest(enabled: Bool, skipMigration: Bool) throws
    func unlockDatabase() throws
    func registerDatabaseLockedHandler(_ handler: @escaping (_ isDatabaseLocked: Bool) -> Void) -> Any
}

protocol UserSessionEncryptionAtRestDelegate: AnyObject {
    func prepareForMigration(for account: Account, onReady: @escaping (NSManagedObjectContext) throws -> Void)
}

extension ZMUserSession: UserSessionEncryptionAtRestInterface {
    /// Enable or disable encryption at rest.
    ///
    /// When toggling encryption at rest the existing database needs to be migrated. The migration happens
    /// asynchronously on the sync context and only after a successful migration is the feature toggled. In
    /// the case that the migration fails, the sync context is reset to a clean state.
    ///
    /// - Parameters:
    ///   - enabled: When **true**, messages will be encrypted at rest.
    ///   - skipMigration: When **true**, existing messsages will not be migrated to be under encryption at rest.
    /// Defaults to **false**.
    ///
    /// - Throws: `MigrationError` if it's not possible to start the migration.

    public func setEncryptionAtRest(
        enabled: Bool,
        skipMigration: Bool = false
    ) throws {
        do {
            WireLogger.ear.info("setting ear enabled (\(enabled))")

            if enabled {
                try earService.enableEncryptionAtRest(
                    context: managedObjectContext,
                    skipMigration: skipMigration
                )
            } else {
                try earService.disableEncryptionAtRest(
                    context: managedObjectContext,
                    skipMigration: skipMigration
                )
            }
        } catch {
            WireLogger.ear.error("failed to set ear enabled (\(enabled)): \(String(describing: error))")
            throw error
        }
    }

    /// Whether encryption at rest is enabled.
    ///
    /// If `true` then sensitive data in the database should be encrypted with the
    /// database key.

    public var encryptMessagesAtRest: Bool {
        guard let context = coreDataStack?.viewContext else { return false }
        return context.encryptMessagesAtRest
    }

    /// Whether the database is currently locked.

    public var isDatabaseLocked: Bool {
        managedObjectContext.isLocked
    }

    /// Register an observer for events when the database becomes locked or unlocked.
    ///
    /// - Parameters:
    ///   - handler: the block that is invoked when the database lock changes.
    ///
    /// - Returns: an observer token to be retained.

    public func registerDatabaseLockedHandler(_ handler: @escaping (_ isDatabaseLocked: Bool) -> Void) -> Any {
        NotificationInContext.addObserver(
            name: DatabaseEncryptionLockNotification.notificationName,
            context: notificationContext,
            queue: .main
        ) { note in
            guard let note = note
                .userInfo[DatabaseEncryptionLockNotification.userInfoKey] as? DatabaseEncryptionLockNotification
            else { return }
            handler(note.databaseIsEncrypted)
        }
    }

    /// Lock the database.
    ///
    /// When locked, the encrypted content of the database can not be decrypted
    /// until the database is unlocked.

    func lockDatabase() {
        guard managedObjectContext.encryptMessagesAtRest else { return }

        BackgroundActivityFactory.shared.notifyWhenAllBackgroundActivitiesEnd { [weak self] in
            self?.earService.lockDatabase()

            if let notificationContext = self?.notificationContext {
                DatabaseEncryptionLockNotification(databaseIsEncrypted: true).post(in: notificationContext)
            }
        }
    }
}

extension ZMUserSession: EARServiceDelegate {
    public func prepareForMigration(onReady: @escaping (NSManagedObjectContext) throws -> Void) {
        delegate?.prepareForMigration(
            for: coreDataStack.account,
            onReady: onReady
        )
    }
}
