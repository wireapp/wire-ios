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

import SwiftUI
import Testing
import WireCallingAssembly
import WireCallingDomainSupport
import WireCallingUI

@Suite("WireMeetingsFactory Tests")
@MainActor
struct WireMeetingsFactoryTests {

    @Test("makeMeetingsView returns a hosting controller for the meetings view")
    func makeMeetingsView() {
        // Given
        let factory = WireMeetingsFactory()

        // When
        let viewController = factory.makeMeetingsView(
            meetingRepository: MeetingRepositoryProtocolMock(),
            memberRepository: MeetingMemberRepositoryProtocolMock(),
            conversationRepository: MeetingConversationRepositoryProtocolMock(),
            callStateRepository: MeetingCallStateRepositoryProtocolMock()
        )

        // Then
        #expect(viewController is UIHostingController<AllMeetingsView>)
    }

}
