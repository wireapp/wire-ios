//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
}

extension ZMMessageTests_Legalhold {

    func testThatItUpdatesLegalHoldStatusFlag_WhenLegalHoldIsEnabled() {
        // given
        let conversation = createConversation(in: uiMOC)
        let message = createClientTextMessage()!
        conversation.append(message)
        var genericMessage = message.underlyingMessage!

        genericMessage.setLegalHoldStatus(.disabled)
        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail("Error in adding data: \(error)")
        }
        conversation.legalHoldStatus = .enabled

        // when
        performPretendingUiMocIsSyncMoc {
            _ = message.encryptForTransport()
        }

        // then
        XCTAssertEqual(message.underlyingMessage?.text.legalHoldStatus, .enabled)
    }

    func testThatItUpdatesLegalHoldStatusFlag_WhenLegalHoldIsDisabled() {
        // given
        let conversation = createConversation(in: uiMOC)
        let message = createClientTextMessage()!
        conversation.append(message)
        var genericMessage = message.underlyingMessage!
        genericMessage.setLegalHoldStatus(.enabled)
        do {
            try message.setUnderlyingMessage(genericMessage)
        } catch {
            XCTFail("Error in adding data: \(error)")
        }
        conversation.legalHoldStatus = .disabled

        // when
        performPretendingUiMocIsSyncMoc {
            _ = message.encryptForTransport()
        }

        // then
        XCTAssertEqual(message.underlyingMessage?.text.legalHoldStatus, .disabled)
    }
}
