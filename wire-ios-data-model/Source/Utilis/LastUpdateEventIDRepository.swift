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

// sourcery: AutoMockable
@objc
public protocol LastEventIDRepositoryInterface {
    func fetchLastEventID() -> UUID?
    func storeLastEventID(_ id: UUID?)
}

@objc
public final class LastEventIDRepository: NSObject, LastEventIDRepositoryInterface {
    // MARK: - Properties

    private let storage: PrivateUserDefaults<Key>

    // MARK: - Types

    private enum Key: String, DefaultsKey {
        case lastEventID
    }

    // MARK: - Life cycle

    @objc
    public init(
        userID: UUID,
        sharedUserDefaults: UserDefaults
    ) {
        self.storage = PrivateUserDefaults(
            userID: userID,
            storage: sharedUserDefaults
        )

        super.init()
    }

    // MARK: - Methods

    public func fetchLastEventID() -> UUID? {
        storage.getUUID(forKey: .lastEventID)
    }

    public func storeLastEventID(_ id: UUID?) {
        WireLogger.sync.info(
            "store last event id",
            attributes: [.lastEventID: String(describing: id?.safeForLoggingDescription ?? "<nil>")]
        )
        storage.setUUID(id, forKey: .lastEventID)
    }
}
