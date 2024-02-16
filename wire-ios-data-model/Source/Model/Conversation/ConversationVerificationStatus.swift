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

public struct ConversationVerificationStatus {

    public var isE2EICertified: Bool // TODO [WPB-765]: consider using WireCoreCrypto.E2eiConversationState or MLSVerificationStatus
    public var isProteusVerified: Bool

    public init(
        isE2EICertified: Bool,
        isProteusVerified: Bool
    ) {
        self.isE2EICertified = isE2EICertified
        self.isProteusVerified = isProteusVerified
    }

    public init() {
        self.init(
            isE2EICertified: false,
            isProteusVerified: false
        )
    }
}
