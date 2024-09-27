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

import WireDataModel
@testable import WireSyncEngine

final class SearchUserImageStrategyTests: MessagingTest {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        mockCache = SearchUsersCache()

        sut = SearchUserImageStrategy(
            applicationStatus: mockApplicationStatus,
            managedObjectContext: uiMOC,
            searchUsersCache: mockCache
        )
    }

    override func tearDown() {
        mockApplicationStatus = nil
        mockCache = nil

        sut = nil

        BackendInfo.domain = nil

        super.tearDown()
    }

    func createSearchUser() -> ZMSearchUser {
        ZMSearchUser(
            contextProvider: coreDataStack,
            name: "Foo",
            handle: "foo",
            accentColor: .amber,
            remoteIdentifier: UUID(),
            searchUsersCache: mockCache
        )
    }

    func userIDs(from searchUsers: Set<ZMSearchUser>) -> Set<UUID> {
        Set(searchUsers.compactMap(\.remoteIdentifier))
    }

    func userData(previewAssetKey: String?, completeAssetKey: String? = nil, for userID: UUID) -> [String: Any] {
        [
            "id": userID.transportString(),
            "assets": assetPayload(previewAssetKey: previewAssetKey, completeAssetKey: completeAssetKey),
        ]
    }

    func assetPayload(previewAssetKey: String?, completeAssetKey: String? = nil) -> [[String: Any]] {
        [
            [
                "size": "preview",
                "type": "image",
                "key": previewAssetKey ?? UUID().transportString(),
            ],
            [
                "size": "complete",
                "type": "image",
                "key": completeAssetKey ?? UUID().transportString(),
            ],
        ]
    }

    func userIDs(in getRequest: ZMTransportRequest) -> Set<UUID> {
        if !getRequest.path.hasPrefix(userRequestURL) {
            return Set()
        }
        let userIDs = String(getRequest.path[userRequestURL.endIndex...])
        let tokens = userIDs.components(separatedBy: ",").compactMap { UUID(uuidString: $0) }
        return Set(tokens)
    }

    func setupSearchDirectory(userCount: Int) -> Set<ZMSearchUser> {
        var users = Set<ZMSearchUser>()
        for _ in 0 ..< userCount {
            let user = createSearchUser()
            users.insert(user)
        }
        return users
    }

    // MARK: - Tests

    func testThatItReturnsNoRequestIfThereIsNoRequestUserProfile() {
        // given
        _ = setupSearchDirectory(userCount: 1)

        // when
        let request = sut.nextRequest(for: .v0)

        // then
        XCTAssertNil(request)
    }

    func testThatNextRequestCreatesARequestForAllUserIDsWeHaveRequested() {
        // given
        let searchSet = setupSearchDirectory(userCount: 3)
        searchSet.forEach { $0.requestPreviewProfileImage() }

        // when
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }

        // then
        XCTAssertNotNil(request)
        XCTAssertEqual(request.method, .get)
        XCTAssertTrue(request.needsAuthentication)

        XCTAssertTrue(request.path.hasPrefix(userRequestURL))
        let expectedUserIDs = userIDs(from: searchSet)
        XCTAssertEqual(userIDs(in: request), expectedUserIDs)
    }

    func testThatNextRequestDoesNotCreateARequestClientNotReady() {
        // given
        let searchSet = setupSearchDirectory(userCount: 3)
        searchSet.forEach { $0.requestPreviewProfileImage() }
        mockApplicationStatus.mockSynchronizationState = .unauthenticated

        // when
        let request = sut.nextRequest(for: .v0)

        // then
        XCTAssertNil(request)
    }

    func testThatNextRequestCreatesARequestForAllUserIDsForAllUserIDsWeHaveRequestedThatWeAreNotAlreadyRequesting() {
        // given
        let searchSet1 = setupSearchDirectory(userCount: 2)
        searchSet1.forEach { $0.requestPreviewProfileImage() }
        guard sut.nextRequest(for: .v0) != nil else { return XCTFail() } // start first request

        // when
        let searchSet2 = setupSearchDirectory(userCount: 1)
        searchSet2.forEach { $0.requestPreviewProfileImage() }
        guard let request2 = sut.nextRequest(for: .v0) else { return XCTFail() }

        // then
        XCTAssertNotNil(request2)
        XCTAssertEqual(request2.method, .get)
        XCTAssertTrue(request2.needsAuthentication)

        let expectedUserIDs = userIDs(from: searchSet2)
        XCTAssertEqual(userIDs(in: request2), expectedUserIDs)
    }

    func testThatCompletingARequestUpdatesAssetKeysOnSearchUsers_AssetKeys() {
        // Given
        let searchUsers = Array(setupSearchDirectory(userCount: 2))
        let searchUser1 = searchUsers.first!
        let searchUser2 = searchUsers.last!
        searchUsers.forEach { $0.requestPreviewProfileImage() }

        let previewAssetKey1 = "previewAssetKey1", completeAssetKey1 = "completeAssetKey1"
        let previewAssetKey2 = "previewAssetKey2", completeAssetKey2 = "completeAssetKey2"

        let payload = [
            userData(
                previewAssetKey: previewAssetKey1,
                completeAssetKey: completeAssetKey1,
                for: searchUser1.remoteIdentifier!
            ),
            userData(
                previewAssetKey: previewAssetKey2,
                completeAssetKey: completeAssetKey2,
                for: searchUser2.remoteIdentifier!
            ),
        ]

        let response = ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // When
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertEqual(searchUser1.assetKeys?.preview, previewAssetKey1)
        XCTAssertEqual(searchUser1.assetKeys?.complete, completeAssetKey1)

        XCTAssertEqual(searchUser2.assetKeys?.preview, previewAssetKey2)
        XCTAssertEqual(searchUser2.assetKeys?.complete, completeAssetKey2)
    }

    func testThatAFailingUserProfileRequestWithAPermanentErrorClearsThemFromTheDownloadQueue() {
        // given
        let searchUsers = setupSearchDirectory(userCount: 2)
        searchUsers.forEach { $0.requestPreviewProfileImage() }
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 400,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatFailingAUserProfileRequestWithATemporaryErrorAllowsThemToBeDownloadedAgain() {
        // given
        let searchUsers = setupSearchDirectory(userCount: 2)
        searchUsers.forEach { $0.requestPreviewProfileImage() }
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 500,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        guard let request1 = sut.nextRequest(for: .v0) else { return XCTFail() }
        request1.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let request2 = sut.nextRequest(for: .v0) else { return XCTFail() }
        let expectedUserIDs = userIDs(from: searchUsers)
        XCTAssertEqual(userIDs(in: request2), expectedUserIDs)
    }

    func testThatCompletingAUserProfileRequestDoesNotAllowForThemToBeDownloadedAgain() {
        // given
        let searchUsers = Array(setupSearchDirectory(userCount: 2))
        searchUsers.forEach { $0.requestPreviewProfileImage() }

        let payload = [
            userData(previewAssetKey: UUID().transportString(), for: searchUsers.first!.remoteIdentifier!),
            userData(previewAssetKey: UUID().transportString(), for: searchUsers.last!.remoteIdentifier!),
        ]
        let response = ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        guard let request1 = sut.nextRequest(for: .v0) else { return XCTFail() }
        request1.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let request2 = sut.nextRequest(for: .v0) else { return XCTFail() }
        XCTAssertEqual(userIDs(in: request2).count, 0)
    }

    // MARK: - ImageAssets

    func testThatNextRequestCreatesARequestForAnAssetID(apiVersion: APIVersion) {
        // given
        let domain = "example.domain.com"
        BackendInfo.domain = domain
        let assetID = UUID().transportString()
        let searchUser = setupSearchDirectory(userCount: 1).first!
        searchUser.update(from: userData(previewAssetKey: assetID, for: searchUser.remoteIdentifier!))
        searchUser.requestPreviewProfileImage()

        // when
        guard let request = sut.nextRequest(for: apiVersion) else { return XCTFail() }

        // then
        XCTAssertNotNil(request)
        XCTAssertEqual(request.method, .get)
        XCTAssertTrue(request.needsAuthentication)

        let expectedPath = switch apiVersion {
        case .v0:
            "/assets/v3/\(assetID)"
        case .v1:
            "/v1/assets/v4/\(domain)/\(assetID)"
        case .v2, .v3, .v4, .v5, .v6:
            "/v\(apiVersion.rawValue)/assets/\(domain)/\(assetID)"
        }

        XCTAssertEqual(request.path, expectedPath)
    }

    func testThatNextRequestCreatesARequestForAnAssetID() {
        testThatNextRequestCreatesARequestForAnAssetID(apiVersion: .v0)
        testThatNextRequestCreatesARequestForAnAssetID(apiVersion: .v1)
        testThatNextRequestCreatesARequestForAnAssetID(apiVersion: .v2)
    }

    func testThatNextRequestDoesNotCreatesARequestForAnAssetIDIfTheFirstRequestIsStillRunning() {
        // given
        let searchUser = setupSearchDirectory(userCount: 1).first!
        let assetID = UUID().transportString()
        searchUser.update(from: userData(previewAssetKey: assetID, for: searchUser.remoteIdentifier!))
        searchUser.requestPreviewProfileImage()

        // when
        let request1 = sut.nextRequest(for: .v0)
        let request2 = sut.nextRequest(for: .v0)

        // then
        XCTAssertNotNil(request1)
        XCTAssertNil(request2)
    }

    func testThatNextRequestCreatesARequestForAnAssetIDThatWeAreNotAlreadyRequesting() {
        // given
        let searchUser1 = setupSearchDirectory(userCount: 1).first!
        let searchUser2 = setupSearchDirectory(userCount: 1).first!

        let assetID1 = UUID().transportString()
        let assetID2 = UUID().transportString()

        searchUser1.update(from: userData(previewAssetKey: assetID1, for: searchUser1.remoteIdentifier!))
        searchUser2.update(from: userData(previewAssetKey: assetID2, for: searchUser2.remoteIdentifier!))
        searchUser1.requestPreviewProfileImage()
        searchUser2.requestPreviewProfileImage()

        // when
        guard let request1 = sut.nextRequest(for: .v0) else { return XCTFail() }
        guard let request2 = sut.nextRequest(for: .v0) else { return XCTFail() }

        // then
        XCTAssertNotNil(request1)
        XCTAssertEqual(request1.method, .get)
        XCTAssertTrue(request1.needsAuthentication)

        XCTAssertNotNil(request2)
        XCTAssertEqual(request2.method, .get)
        XCTAssertTrue(request2.needsAuthentication)

        let expectedPath1 = "/assets/v3/\(assetID1)" // requestPath(for:assetID1, of:searchUser1.remoteIdentifier!)
        let expectedPath2 = "/assets/v3/\(assetID2)" // requestPath(for:assetID2, of:searchUser2.remoteIdentifier!)
        XCTAssertTrue(request1.path == expectedPath1 || request1.path == expectedPath2)
        XCTAssertTrue(request2.path == expectedPath1 || request2.path == expectedPath2)
        XCTAssertNotEqual(request2.path, request1.path)
    }

    func testThatCompletingARequestUpdatesTheImageDataOnSearchUser() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser1 = setupSearchDirectory(userCount: 1).first!
        let assetID1 = UUID().transportString()
        searchUser1.update(from: userData(previewAssetKey: assetID1, for: searchUser1.remoteIdentifier!))
        searchUser1.requestPreviewProfileImage()

        let response = ZMTransportResponse(
            imageData: imageData,
            httpStatus: 200,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }
        XCTAssertEqual(request.path, "/assets/v3/\(assetID1)")

        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(searchUser1.previewImageData, imageData)
    }

    func testThatCompletingARequestRemovesTheAssetFromTheDownloadQueue() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser1 = setupSearchDirectory(userCount: 1).first!
        let assetID1 = UUID().transportString()
        searchUser1.update(from: userData(previewAssetKey: assetID1, for: searchUser1.remoteIdentifier!))
        searchUser1.requestPreviewProfileImage()

        let response = ZMTransportResponse(
            imageData: imageData,
            httpStatus: 200,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }
        XCTAssertEqual(request.path, "/assets/v3/\(assetID1)")

        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatFailingAnAssetRequestWithAPermanentErrorDeletesAssetKeysFromSearchUser() {
        // given
        let searchUser1 = setupSearchDirectory(userCount: 1).first!
        let assetID1 = UUID().transportString()
        searchUser1.update(from: userData(previewAssetKey: assetID1, for: searchUser1.remoteIdentifier!))
        searchUser1.requestPreviewProfileImage()
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 400,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }
        XCTAssertEqual(request.path, "/assets/v3/\(assetID1)")

        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(searchUser1.assetKeys)
    }

    func testThatFailingAnAssertRequestWithATemporaryErrorAllowsForThoseAssetIDsToBeDownloadedAgain() {
        // given
        let searchUser1 = setupSearchDirectory(userCount: 1).first!
        let assetID1 = UUID().transportString()
        searchUser1.update(from: userData(previewAssetKey: assetID1, for: searchUser1.remoteIdentifier!))
        searchUser1.requestPreviewProfileImage()

        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 500,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )

        // when
        guard let request1 = sut.nextRequest(for: .v0) else { return XCTFail() }
        XCTAssertEqual(request1.path, "/assets/v3/\(assetID1)")

        request1.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let request2 = sut.nextRequest(for: .v0) else { return XCTFail() }
        XCTAssertEqual(request2.path, "/assets/v3/\(assetID1)")
    }

    func testThatItNotifiesTheSearchUserWhenAnImageIsDownloaded_preview() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser1 = setupSearchDirectory(userCount: 1).first!
        let assetID1 = UUID().transportString()
        searchUser1.update(from: userData(previewAssetKey: assetID1, for: searchUser1.remoteIdentifier!))
        searchUser1.requestPreviewProfileImage()

        let response = ZMTransportResponse(
            imageData: imageData,
            httpStatus: 200,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        uiMOC.searchUserObserverCenter
            .addSearchUser(searchUser1) // This is called when the searchDirectory returns the searchUsers
        let userObserver = UserObserver(user: searchUser1, managedObjectContext: uiMOC)!

        // when
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let note = userObserver.notifications.firstObject as? UserChangeInfo else { return XCTFail() }
        XCTAssertTrue(note.imageSmallProfileDataChanged)
        XCTAssertEqual(note.user as? ZMSearchUser, searchUser1)
    }

    func testThatItNotifiesTheSearchUserWhenAnImageIsDownloaded_complete() {
        // given
        let imageData = verySmallJPEGData()
        let searchUser1 = setupSearchDirectory(userCount: 1).first!
        let previewAssetKey = "previewKey123"
        let completeAssetKey = "previewKey123"
        searchUser1.update(from: userData(
            previewAssetKey: previewAssetKey,
            completeAssetKey: completeAssetKey,
            for: searchUser1.remoteIdentifier!
        ))
        searchUser1.requestCompleteProfileImage()

        let response = ZMTransportResponse(
            imageData: imageData,
            httpStatus: 200,
            transportSessionError: nil,
            headers: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        uiMOC.searchUserObserverCenter
            .addSearchUser(searchUser1) // This is called when the searchDirectory returns the searchUsers
        let userObserver = UserObserver(user: searchUser1, managedObjectContext: uiMOC)!

        // when
        guard let request = sut.nextRequest(for: .v0) else { return XCTFail() }
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let note = userObserver.notifications.firstObject as? UserChangeInfo else { return XCTFail() }
        XCTAssertTrue(note.imageMediumDataChanged)
        XCTAssertEqual(note.user as? ZMSearchUser, searchUser1)
    }

    // MARK: Private

    private let userRequestURL = "/users?ids="

    private var sut: SearchUserImageStrategy!

    private var mockApplicationStatus: MockApplicationStatus!
    private var mockCache: SearchUsersCache!
}
