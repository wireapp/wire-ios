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

import SwiftUI
import WireDataModel

struct GroupConversationVerificationStatusView: View {

    let status: ConversationVerificationStatus

    var body: some View {
        Text("TODO")
    }
}

#Preview("neither nor") {
    GroupConversationVerificationStatusView(
        status: .init(
            e2eiCertificationStatus: false,
            proteusVerificationStatus: false
        )
    )
}

#Preview("verified") {
    GroupConversationVerificationStatusView(
        status: .init(
            e2eiCertificationStatus: false,
            proteusVerificationStatus: true
        )
    )
}

#Preview("certified") {
    GroupConversationVerificationStatusView(
        status: .init(
            e2eiCertificationStatus: true,
            proteusVerificationStatus: false
        )
    )
}

#Preview("both") {
    GroupConversationVerificationStatusView(
        status: .init(
            e2eiCertificationStatus: true,
            proteusVerificationStatus: true
        )
    )
}
