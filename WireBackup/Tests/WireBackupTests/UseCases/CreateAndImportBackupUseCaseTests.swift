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

final class CreateAndImportBackupUseCaseTests: XCTestCase {

    private typealias BackupLocalStoreMock = BackupLocalStoreProtocolMock
    private typealias FileArchiverMock = FileArchiverProtocolMock
    private typealias FileUnarchiverMock = FileUnarchiverProtocolMock

    private var backupLocalStoreMock: BackupLocalStoreMock!
    private var fileArchiverMock: FileArchiverMock!
    private var fileUnarchiverMock: FileUnarchiverMock!
    private var dateProviderMock: CurrentDateProvidingMock!
    private var createBackupUseCase: CreateBackupUseCase<
        BackupLocalStoreMock,
        FileArchiverMock
    >!
    private var importBackupUseCase: ImportBackupUseCase<
        BackupLocalStoreMock,
        FileUnarchiverMock
    >!
    private var syncTriggerExpectation: XCTestExpectation!

    override func setUpWithError() throws {

        backupLocalStoreMock = .init()
        fileArchiverMock = .init()
        fileUnarchiverMock = .init()
        dateProviderMock = .init()

        let selfUserID = QualifiedID(id: UUID(), domain: "wire.com")
        createBackupUseCase = CreateBackupUseCase(
            selfUserID: selfUserID,
            selfUserHandle: "handle",
            backupLocalStore: backupLocalStoreMock,
            fileArchiver: fileArchiverMock,
            currentDateProvider: dateProviderMock,
            logger: WireLogger(tag: "???")
        )
        let syncTriggerExpectation = XCTestExpectation()
        self.syncTriggerExpectation = syncTriggerExpectation
        importBackupUseCase = ImportBackupUseCase(
            selfUserID: selfUserID,
            backupLocalStore: backupLocalStoreMock,
            fileUnarchiver: fileUnarchiverMock,
            syncTrigger: { syncTriggerExpectation.fulfill() },
            logger: WireLogger(tag: "???")
        )
    }

    override func tearDownWithError() throws {
        importBackupUseCase = nil
        createBackupUseCase = nil
        dateProviderMock = nil
        fileArchiverMock = nil
        backupLocalStoreMock = nil
    }

    func testCreateAndImport() async throws {

        let user = UserBackupModel(
            qualifiedID: QualifiedID(id: UUID(), domain: "wire.com"),
            name: "Somebody",
            handle: "sb"
        )
        let conversation = ConversationBackupModel(
            qualifiedID: QualifiedID(id: UUID(), domain: "wire.com"),
            name: "some conversation"
        )
        let message = MessageBackupModel(
            id: UUID().uuidString,
            conversationID: conversation.qualifiedID,
            senderUserID: user.qualifiedID,
            senderClientID: .none,
            creationDate: .now,
            content: .text("some message")
        )
        let password = UUID().uuidString

        backupLocalStoreMock.countModels_UserCountIntConversationCountIntMessageCountIntReturnValue = (1, 1, 1)
        let (userStream, userContinuation) = AsyncThrowingStream.makeStream(
            of: UserBackupModel.self,
            bufferingPolicy: .unbounded
        )
        backupLocalStoreMock.fetchAllUsersAsyncThrowingStreamUserBackupModelAnyErrorReturnValue = userStream
        userContinuation.yield(user)
        userContinuation.finish()

        let events = try await createBackupUseCase.invoke(password: password)
            .reduce(into: [CreateBackupProgress]()) { $0 += [$1] }
        XCTAssertEqual(events, [])

    }

}
