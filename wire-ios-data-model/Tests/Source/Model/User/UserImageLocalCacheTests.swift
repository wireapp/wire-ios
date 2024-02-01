// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

final class UserImageLocalCacheTests: XCTestCase {

    private let coreDataStackHelper = CoreDataStackHelper()

    private var tmpDirectory: URL { coreDataStackHelper.storageDirectory }

    var coreDataStack: CoreDataStack!
    var context: NSManagedObjectContext!

    var testUserIdentifier: UUID!
    var testUser: ZMUser!
    var sut: UserImageLocalCache!

    override func setUp() async throws {
        try await super.setUp()

        let testUserIdentifier = UUID()
        self.testUserIdentifier = testUserIdentifier

        coreDataStack = try await coreDataStackHelper.createStack(at: tmpDirectory)
        context = coreDataStack.viewContext

        testUser = await context.perform {
            let testUser = ZMUser.insertNewObject(in: self.context)
            testUser.remoteIdentifier = testUserIdentifier
            testUser.previewProfileAssetIdentifier = "preview"
            testUser.completeProfileAssetIdentifier = "complete"
            return testUser
        }

        debugPrint("this is before sut is touched")

        sut = makeCache()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        context = nil
        testUser = nil
        sut = nil

        try coreDataStackHelper.cleanupDirectory(tmpDirectory)

        try await super.tearDown()
    }

    func testThatItHasNilData() {
        XCTAssertNil(sut.userImage(testUser, size: .preview))
        XCTAssertNil(sut.userImage(testUser, size: .complete))
    }

    func testThatPersistedDataCanBeRetrievedAsynchronously() {
        // given
        let largeData = "LARGE".data(using: .utf8)!
        let smallData = "SMALL".data(using: .utf8)!

        // when
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)
        sut = makeCache()

        // then
        let previewImageArrived = expectation(description: "Preview image arrived")
        let completeImageArrived = expectation(description: "Complete image arrived")
        sut.userImage(testUser, size: .preview, queue: .global()) { smallDataResult in
            XCTAssertEqual(smallDataResult, smallData)
            previewImageArrived.fulfill()
        }

        sut.userImage(testUser, size: .complete, queue: .global()) { largeDataResult in
            XCTAssertEqual(largeDataResult, largeData)
            completeImageArrived.fulfill()
        }

        waitForExpectations(timeout: 0.5)
    }

    // MARK: - Storing

    func testThatItHasNilDataWhenNotSetForV3() {
        XCTAssertNil(sut.userImage(testUser, size: .preview))
        XCTAssertNil(sut.userImage(testUser, size: .complete))
    }

    func testThatItSetsSmallAndLargeUserImageForV3() throws {

        // given
        let largeData = try XCTUnwrap("LARGE".data(using: .utf8))
        let smallData = try XCTUnwrap("SMALL".data(using: .utf8))

        // when
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)

        // then
        XCTAssertEqual(sut.userImage(testUser, size: .complete), largeData)
        XCTAssertEqual(sut.userImage(testUser, size: .preview), smallData)

    }

    func testThatItPersistsSmallAndLargeUserImageForV3() throws {

        // given
        let largeData = try XCTUnwrap("LARGE".data(using: .utf8))
        let smallData = try XCTUnwrap("SMALL".data(using: .utf8))

        // when
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)
        sut = makeCache()

        // then
        XCTAssertEqual(sut.userImage(testUser, size: .complete), largeData)
        XCTAssertEqual(sut.userImage(testUser, size: .preview), smallData)
    }

    // MARK: - Retrieval

    func testThatItReturnsV3AssetsWhenPresent() throws {
        // given
        let largeData = try XCTUnwrap("LARGE".data(using: .utf8))
        let smallData = try XCTUnwrap("SMALL".data(using: .utf8))

        // when
        XCTAssertNil(sut.userImage(testUser, size: .complete))
        XCTAssertNil(sut.userImage(testUser, size: .preview))
        sut.setUserImage(testUser, imageData: largeData, size: .complete)
        sut.setUserImage(testUser, imageData: smallData, size: .preview)

        // then
        XCTAssertEqual(sut.userImage(testUser, size: .complete), largeData)
        XCTAssertEqual(sut.userImage(testUser, size: .preview), smallData)
    }

    // MARK: - Removal

    func testThatItRemovesAllImagesFromCache() throws {
        // given
        sut.setUserImage(
            testUser,
            imageData: try XCTUnwrap("baz".data(using: .utf8)),
            size: .complete
        )
        sut.setUserImage(
            testUser,
            imageData: try XCTUnwrap("moo".data(using: .utf8)),
            size: .preview
        )

        // when
        sut.removeAllUserImages(testUser)

        // then
        XCTAssertNil(sut.userImage(testUser, size: .complete))
        XCTAssertNil(sut.userImage(testUser, size: .preview))
    }

    // MARK: - Helpers

    private func makeCache() -> UserImageLocalCache {
        let directory = tmpDirectory.appendingPathComponent(testUserIdentifier.uuidString, isDirectory: true)
        debugPrint("makeCache at directory: \(directory)")
        return UserImageLocalCache(location: directory)
    }
}
