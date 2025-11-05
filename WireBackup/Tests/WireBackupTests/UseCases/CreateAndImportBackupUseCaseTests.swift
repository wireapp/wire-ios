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
import WireLoggingSupport
import WireUtilitiesPackage
import XCTest

@testable import WireBackup

final class CreateAndImportBackupUseCaseTests: XCTestCase {

    private typealias BackupLocalStoreMock = BackupLocalStoreProtocolMock

    private var backupLocalStoreMock: BackupLocalStoreMock!
    private var fileArchiver: ZIPFoundationFileArchiver!
    private var fileUnarchiver: ZIPFoundationFileUnarchiver!
    private var createBackupUseCase: CreateBackupUseCase!
    private var importBackupUseCaseFactory: ((_ url: URL) -> ImportBackupUseCase)!
    private var syncTriggerExpectation: XCTestExpectation!

    override func setUpWithError() throws {

        backupLocalStoreMock = .init()
        fileArchiver = .init()
        fileUnarchiver = .init()

        let logger = WireTaggedLogger(tag: "???", handler: WireLogHandlerProtocolMock())
        let selfUserID = QualifiedID(id: UUID(), domain: "wire.com")
        createBackupUseCase = CreateBackupUseCase(
            selfUserID: selfUserID,
            backupLocalStore: backupLocalStoreMock,
            fileArchiver: fileArchiver,
            logger: logger
        )

        let syncTriggerExpectation = XCTestExpectation()
        self.syncTriggerExpectation = syncTriggerExpectation
        importBackupUseCaseFactory = { [backupLocalStoreMock, fileUnarchiver] url in
            ImportBackupUseCase(
                url: url,
                selfUserID: selfUserID,
                backupLocalStore: backupLocalStoreMock!,
                fileUnarchiver: fileUnarchiver!,
                syncTrigger: { syncTriggerExpectation.fulfill() },
                logger: logger
            )
        }
    }

    override func tearDownWithError() throws {
        importBackupUseCaseFactory = nil
        createBackupUseCase = nil
        fileArchiver = nil
        fileUnarchiver = nil
        backupLocalStoreMock = nil
    }

    func testCreateAndImport() async throws {

        // create

        let user = exampleUser
        let conversation = exampleConversation
        let message = exampleMessage(of: user, in: conversation)

        backupLocalStoreMock.countModels_UserCountIntConversationCountIntMessageCountIntReturnValue = (1, 1, 1)
        backupLocalStoreMock.fetchAllUsersAsyncThrowingStreamUserBackupModelAnyErrorReturnValue =
            .makeStream(of: [user])
        backupLocalStoreMock.fetchAllConversationsAsyncThrowingStreamConversationBackupModelAnyErrorReturnValue =
            .makeStream(of: [conversation])
        backupLocalStoreMock.fetchAllMessagesAsyncThrowingStreamMessageBackupModelAnyErrorReturnValue =
            .makeStream(of: [message])

        let password = UUID().uuidString
        let createEvents = try await createBackupUseCase.invoke(password: password)
            .reduce(into: [CreateBackupProgress]()) { $0 += [$1] }
        guard case let .done(backupURL) = createEvents.last else { return XCTFail("backup url missing") }

        // import

        backupLocalStoreMock.fetchAllUserIDsSetQualifiedIDReturnValue = []
        backupLocalStoreMock.fetchAllMessageIDsSetStringReturnValue = []

        let importBackupUseCase = importBackupUseCaseFactory(backupURL)
        let importEvents = try await importBackupUseCase.invoke(password: password)
            .reduce(into: [ImportBackupProgress]()) { $0 += [$1] }
        await fulfillment(of: [syncTriggerExpectation], timeout: 1)

        XCTAssertEqual(importEvents.last, .done)
        XCTAssertEqual(backupLocalStoreMock.addUserUserUserBackupModelVoidReceivedInvocations, [user])
        XCTAssertEqual(
            backupLocalStoreMock.addMessagesBackupMessagesMessageBackupModelVoidReceivedInvocations,
            [[message]]
        )

    }

    private var exampleUser: UserBackupModel {
        UserBackupModel(
            qualifiedID: QualifiedID(id: UUID(), domain: "wire.com"),
            name: "Somebody",
            handle: "sb"
        )
    }

    private var exampleConversation: ConversationBackupModel {
        ConversationBackupModel(
            qualifiedID: QualifiedID(id: UUID(), domain: "wire.com"),
            name: "some conversation"
        )
    }

    private func exampleMessage(
        of user: UserBackupModel,
        in conversation: ConversationBackupModel
    ) -> MessageBackupModel {
        MessageBackupModel(
            id: UUID().uuidString.lowercased(),
            conversationID: conversation.qualifiedID,
            senderUserID: user.qualifiedID,
            senderClientID: .none,
            creationDate: try! Date.ISO8601FormatStyle().parse("2025-05-26T11:50:17+02:00"),
            content: .text("some message")
        )
    }

}

// MARK: -

private extension AsyncThrowingStream where Element: Sendable, Failure == (any Error) {

    static func makeStream(of elements: [Element]) -> Self {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: Element.self, bufferingPolicy: .unbounded)
        for element in elements {
            continuation.yield(element)
        }
        continuation.finish()
        return stream
    }
}
