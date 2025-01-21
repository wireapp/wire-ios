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

import XCTest
import WireDataModelSupport

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class ImportBackupUseCaseTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var sut: ImportBackupUseCase!

    override func setUp() async throws {

        coreDataStack = try await CoreDataStackHelper()
            .createStack(inMemoryStore: true)

//        let selfUser = ModelHelper()
//            .createSelfUser(in: coreDataStack.viewContext)

//        sut = .init(
//            userSession: <#T##() -> ZMUserSession?#>,
//            dispatchGroup: <#T##ZMSDispatchGroup#>,
//            fileArchiver: <#T##any ImportBackupFileArchiverProtocol#>,
//            entityStorage: <#T##any ImportBackupEntityStorageProtocol#>,
//            appStateUpdater: <#T##any ImportBackupAppStateUpdaterProtocol#>,
//            sharedContainerURL: <#T##URL#>,
//            logger: .init(tag: "mock")
//        )
    }

    override func tearDownWithError() throws {
        sut = nil
        coreDataStack = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

}
