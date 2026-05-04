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

public import WireAccountImageUI

public struct ConversationTitleSource {
    public let accountImageSource: AccountImageSource?
    public let title: String
    public let subtitle: String?
    public let isMLS: Bool
    public let isVerified: Bool
    public let isUnderLegalHold: Bool

    public init(
        accountImageSource: AccountImageSource?,
        title: String,
        subtitle: String?,
        isMLS: Bool,
        isVerified: Bool,
        isUnderLegalHold: Bool
    ) {
        self.accountImageSource = accountImageSource
        self.title = title
        self.subtitle = subtitle
        self.isMLS = isMLS
        self.isVerified = isVerified
        self.isUnderLegalHold = isUnderLegalHold
    }
}
