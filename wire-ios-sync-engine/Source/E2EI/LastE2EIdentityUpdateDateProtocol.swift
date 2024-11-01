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

import WireFoundation

@objc
public protocol LastE2EIdentityUpdateDateRepositoryInterface {

    func fetchLastAlertDate() -> Date?
    func storeLastAlertDate(_ date: Date?)

}

@objc
public final class LastE2EIdentityUpdateDateRepository: NSObject, LastE2EIdentityUpdateDateRepositoryInterface {

    // MARK: - Properties

    private let storage: PrivateUserDefaults<Key>

    // MARK: - Types

    private enum Key: String, DefaultsKey {
        case lastE2EIdenityUpdateDate
    }

    // MARK: - Life cycle

    @objc
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

    // MARK: - Methods
    public func fetchLastAlertDate() -> Date? {
        storage.date(forKey: .lastE2EIdenityUpdateDate)
    }

    public func storeLastAlertDate(_ date: Date?) {
        storage.set(date, forKey: .lastE2EIdenityUpdateDate)
    }

}
