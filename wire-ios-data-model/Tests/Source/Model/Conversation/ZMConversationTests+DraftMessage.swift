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

import Foundation
@testable import WireDataModel

class ConversationTests_DraftMessage: ZMConversationTestsBase {

    private var earMessageEncryptionService: EARMessageEncryptionService!
    private var earStorage: EARStorage!
    
    override func setUp() {
        super.setUp()

        createSelfClient(onMOC: uiMOC)
        earStorage = EARStorage(userID: UUID(), sharedUserDefaults: .temporary())
        earMessageEncryptionService = EARMessageEncryptionService(earStorage: earStorage)
        uiMOC.earMessageEncryptionService = earMessageEncryptionService
    }

    override func tearDown() {
        earStorage = nil
        earMessageEncryptionService = nil
        super.tearDown()
    }
    
    // MARK: Persist encrypted draft message

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func testThatItEncryptsDraftMessage_WhenEncryptionAtRestIsEnabled() {
        // GIVEN
        setEAREnabled(true)
        earMessageEncryptionService.setDatabaseKey(validDatabaseKey)

        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // WHEN
        conversation.draftMessage = DraftMessage(text: "Draft test", mentions: [], quote: nil)

        // THEN
        XCTAssertNotNil(conversation.draftMessage)
        XCTAssertNotNil(conversation.draftMessageNonce)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func testThatItDiscardsDraftMessage_WhenEncryptionAtRestIsEnabled_And_DatabaseKeyIsMissing() {
        // GIVEN
        setEAREnabled(true)
        earMessageEncryptionService.setDatabaseKey(nil)

        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // WHEN
        conversation.draftMessage = DraftMessage(text: "Draft test", mentions: [], quote: nil)

        // THEN
        XCTAssertNil(conversation.draftMessage)
        XCTAssertNil(conversation.draftMessageNonce)
    }

    // MARK: Access encrypted draft message

    func testThatEncryptedDraftMessageCanBeAccessed_WhenDatabaseKeyIsAvailable() {
        // GIVEN
        setEAREnabled(true)
        earMessageEncryptionService.setDatabaseKey(validDatabaseKey)

        let draftText = "Draft test"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.draftMessage = DraftMessage(text: draftText, mentions: [], quote: nil)

        // WHEN / THEN
        XCTAssertEqual(conversation.draftMessage?.text, draftText)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func testThatEncryptedDraftMessageCantBeAccessed_WhenDatabaseKeyIsMissing() {
        // GIVEN
        setEAREnabled(true)
        earMessageEncryptionService.setDatabaseKey(validDatabaseKey)

        let draftText = "Draft test"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.draftMessage = DraftMessage(text: draftText, mentions: [], quote: nil)

        // WHEN
        earMessageEncryptionService.setDatabaseKey(nil)

        // THEN
        XCTAssertNil(conversation.draftMessage)
    }
    
    private func setEAREnabled(_ enabled: Bool) {
        uiMOC.encryptMessagesAtRest = enabled
        earStorage.enableEAR(enabled)
    }

}
