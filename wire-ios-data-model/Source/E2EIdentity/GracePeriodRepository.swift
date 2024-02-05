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

public protocol GracePeriodRepositoryInterface {

    func fetchEndGracePeriodDate() -> Date?
    func storeEndGracePeriodDate(_ date: Date?)

}

/// The repository is responsible for storing the grace period during which the user must enroll the end-to-end identity certificate.
/// The grace period starts at the moment where the client fetches and processes the team feature flag.
public final class GracePeriodRepository: NSObject, GracePeriodRepositoryInterface {

    // MARK: - Properties

    private let storage: PrivateUserDefaults<Key>

    // MARK: - Types

    private enum Key: String, DefaultsKey {
        case endGracePeriod
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

    public func fetchEndGracePeriodDate() -> Date? {
        storage.date(forKey: .endGracePeriod)
    }

    public func storeEndGracePeriodDate(_ date: Date?) {
        storage.set(date, forKey: .endGracePeriod)
    }

}
