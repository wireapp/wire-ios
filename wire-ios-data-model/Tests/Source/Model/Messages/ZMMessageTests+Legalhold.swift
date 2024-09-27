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

import WireTesting
@testable import WireDataModel

class ZMMessageTests_Legalhold: BaseZMClientMessageTests {
    func testThatItUpdatesLegalHoldStatusFlag_WhenLegalHoldIsEnabled() async throws {
        try await internalTestThatItUpdatesLegalHoldStatusFlag_WhenLegalHold(enabled: true)
    }

    func testThatItUpdatesLegalHoldStatusFlag_WhenLegalHoldIsDisabled() async throws {
        try await internalTestThatItUpdatesLegalHoldStatusFlag_WhenLegalHold(enabled: false)
    }

    func internalTestThatItUpdatesLegalHoldStatusFlag_WhenLegalHold(enabled: Bool) async throws {
        // given
        let message = try await syncMOC.perform { [self] in
            let conversation = createConversation(in: syncMOC)
            let message = try XCTUnwrap(createClientTextMessage(in: syncMOC))
            conversation.append(message)
            var genericMessage = try XCTUnwrap(message.underlyingMessage)

            genericMessage.setLegalHoldStatus(enabled ? .disabled : .enabled)
            try message.setUnderlyingMessage(genericMessage)
            conversation.legalHoldStatus = enabled ? .enabled : .disabled
            return message
        }

        // when
        _ = await message.encryptForTransport()

        // then
        await syncMOC.perform {
            XCTAssertEqual(message.underlyingMessage?.text.legalHoldStatus, enabled ? .enabled : .disabled)
        }
    }
}
