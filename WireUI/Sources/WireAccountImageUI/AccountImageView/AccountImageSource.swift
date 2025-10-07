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

import UIKit

public enum AccountImageSource: Hashable, Sendable {
    case image(UIImage)
    case text(_ initials: String)
    public init() { self = .text("") }
}


public enum LegalHoldStatus { case disabled, pending, enabled }

public struct AccountUIViewModel {
    let avatarSource: AccountImageSource
    let availability: Availability
    let showNotificationsBadge: Bool
    let legalHoldStatus: LegalHoldStatus
    let isE2EICertified: Bool
    let isProteusVerified: Bool
    let action: () -> Void
    let onLegalHoldRequest: (() -> Void)?
    let onLegalHoldInfo: (() -> Void)?
}
