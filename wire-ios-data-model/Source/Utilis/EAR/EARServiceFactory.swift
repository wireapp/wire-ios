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

/// `ZMUserSession.init` needs to create an object which conforms to `EARServiceInterface`.
/// This protocol allows for providing it a mock factory for unit tests.
public protocol EARServiceFactory {
    func create(
        accountID: UUID,
        databaseContexts: [NSManagedObjectContext],
        canPerformKeyMigration: Bool,
        sharedUserDefaults: UserDefaults
    ) -> EARServiceInterface
}

extension EARServiceFactory where Self == DefaultEARServiceFactory {
    public static var `default`: Self { .init() }
}

public struct DefaultEARServiceFactory: EARServiceFactory {

    public func create(
        accountID: UUID,
        databaseContexts: [NSManagedObjectContext],
        canPerformKeyMigration: Bool,
        sharedUserDefaults: UserDefaults
    ) -> EARServiceInterface {
        EARService(
            accountID: accountID,
            databaseContexts: databaseContexts,
            canPerformKeyMigration: canPerformKeyMigration,
            sharedUserDefaults: sharedUserDefaults
        )
    }
}
