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

import WireBackupSupport
import WireFoundation
import WireFoundationSupport
import WireLogging
import XCTest

@testable import WireBackup

final class CreateBackupUseCaseTests: XCTestCase {

    private typealias UserStoreMock = UserStoreProtocolMock<UserEntityProtocolMock>
    private typealias ConversationStoreMock = ConversationStoreProtocolMock<ConversationEntityProtocolMock>
    private typealias MessageStoreMock = MessageStoreProtocolMock<MessageEntityProtocolMock>
    private typealias FileArchiverMock = FileArchiverProtocolMock

    private var userStoreMock: UserStoreMock!
    private var conversationStoreMock: ConversationStoreMock!
    private var messageStoreMock: MessageStoreMock!
    private var fileArchiverMock: FileArchiverMock!
    private var dateProviderMock: CurrentDateProvidingMock!
    private var sut: CreateBackupUseCase<
        UserStoreMock,
        ConversationStoreMock,
        MessageStoreMock,
        FileArchiverMock
    >!

    override func setUpWithError() throws {

        userStoreMock = .init()
        conversationStoreMock = .init()
        messageStoreMock = .init()
        fileArchiverMock = .init()
        dateProviderMock = .init()

        sut = CreateBackupUseCase(
            userStore: userStoreMock,
            conversationStore: conversationStoreMock,
            messageStore: messageStoreMock,
            eventProcessorHandle: .none,
            fileArchiver: fileArchiverMock,
            currentDateProvider: dateProviderMock,
            selfUserID: QualifiedID(id: UUID(), domain: ""),
            selfUserHandle: "handle",
            logger: WireLogger(tag: "???")
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        dateProviderMock = nil
        fileArchiverMock = nil
        messageStoreMock = nil
        conversationStoreMock = nil
        userStoreMock = nil
    }

    func testExample() throws {
        XCTFail("TODO: implement")
    }

}
