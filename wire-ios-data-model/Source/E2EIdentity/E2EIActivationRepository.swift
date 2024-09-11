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

/// The repository is responsible for storing the e2ei activation date.
/// The e2ei activation date begins from the moment the client receives the notification that the feature flag is
/// enabled for the team.
public protocol E2EIActivationDateRepositoryProtocol {
    var e2eiActivatedAt: Date? { get }
    func storeE2EIActivationDate(_ date: Date)
    func removeE2EIActivationDate()
}

public final class E2EIActivationDateRepository: NSObject, E2EIActivationDateRepositoryProtocol {
    // MARK: - Properties

    private let storage: PrivateUserDefaults<Key>

    // MARK: - Types

    private enum Key: String, DefaultsKey {
        case e2eiActivatedAt
    }

    // MARK: - Life cycle

    public init(
        userID: UUID,
        sharedUserDefaults: UserDefaults
    ) {
        storage = PrivateUserDefaults(
            userID: userID,
            storage: sharedUserDefaults
        )

        super.init()
    }

    // MARK: - Public

    public var e2eiActivatedAt: Date? {
        storage.date(forKey: .e2eiActivatedAt)
    }

    public func storeE2EIActivationDate(_ date: Date) {
        storage.set(date, forKey: .e2eiActivatedAt)
    }

    public func removeE2EIActivationDate() {
        storage.removeObject(forKey: .e2eiActivatedAt)
    }
}
