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
import WireDataModel

// MARK: - SelfUserProviderProtocol

// sourcery: AutoMockable
public protocol SelfUserProviderProtocol {
    func fetchSelfUser() -> ZMUser
}

// MARK: - SelfUserProvider

@available(*, deprecated, message: "Use UserRepository instead")
public final class SelfUserProvider: SelfUserProviderProtocol {
    // MARK: Lifecycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: Public

    // MARK: - Methods

    public func fetchSelfUser() -> ZMUser {
        ZMUser.selfUser(in: context)
    }

    // MARK: Private

    // MARK: - Properties

    private let context: NSManagedObjectContext
}
