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

import Foundation
public import Combine
public import UIKit

public final class AccountAvatarViewModel: ObservableObject {

    @Published public var accountImageSource: AccountImageSource
    @Published public var availability: Availability?
    @Published var showNotificationsBadge: Bool

    public var onAvatarTapped: (() -> Void)?

    public init(
        accountImageSource: AccountImageSource = .text(""),
        availability: Availability? = nil,
        showNotificationsBadge: Bool = false
    ) {
        self.accountImageSource = accountImageSource
        self.availability = availability
        self.showNotificationsBadge = showNotificationsBadge
    }

    public func handleAvatarTap() {
        onAvatarTapped?()
    }
}

// MARK: - Supporting Types

public enum AccountImageSource: Equatable {
    case image(UIImage)
    case text(String)
}

public enum Availability {
    case available
    case away
    case busy
    case none
}
