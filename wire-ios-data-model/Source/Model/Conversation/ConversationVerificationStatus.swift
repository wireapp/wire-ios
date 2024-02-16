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

/// TODO: add documentation
public struct ConversationVerificationStatus {

    /// TODO: add documentation
    public var e2eiCertificationStatus: Bool // TODO [WPB-765]: consider using WireCoreCrypto.E2eiConversationState or MLSVerificationStatus

    /// TODO: add documentation
    public var proteusVerificationStatus: Bool

    public init(
        e2eiCertificationStatus: Bool,
        proteusVerificationStatus: Bool
    ) {
        self.e2eiCertificationStatus = e2eiCertificationStatus
        self.proteusVerificationStatus = proteusVerificationStatus
    }

    public init() {
        self.init(
            e2eiCertificationStatus: false,
            proteusVerificationStatus: false
        )
    }
}
