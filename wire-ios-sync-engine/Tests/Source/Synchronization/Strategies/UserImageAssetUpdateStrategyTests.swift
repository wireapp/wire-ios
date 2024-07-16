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

import Foundation
@testable import WireSyncEngine
import XCTest

typealias ProfileImageSize = WireSyncEngine.ProfileImageSize

class MockImageUpdateStatus: WireSyncEngine.UserProfileImageUploadStatusProtocol {
    var allSizes: [ProfileImageSize] { return [.preview, .complete] }

    var assetIdsToDelete = Set<String>()
    func hasAssetToDelete() -> Bool {
        return !assetIdsToDelete.isEmpty
    }
    func consumeAssetToDelete() -> String? {
        return assetIdsToDelete.removeFirst()
    }

    var dataToConsume = [ProfileImageSize: Data]()
    func consumeImage(for size: ProfileImageSize) -> Data? {
        return dataToConsume[size]
    }
    func hasImageToUpload(for size: ProfileImageSize) -> Bool {
        return dataToConsume[size] != nil
    }

    var uploadDoneForSize: ProfileImageSize?
    var uploadDoneWithAssetId: String?
    func uploadingDone(imageSize: ProfileImageSize, assetId: String) {
        uploadDoneForSize = imageSize
        uploadDoneWithAssetId = assetId
    }

    var uploadFailedForSize: ProfileImageSize?
    var uploadFailedWithError: Error?
    func uploadingFailed(imageSize: ProfileImageSize, error: Error) {
        uploadFailedForSize = imageSize
        uploadFailedWithError = error
    }
}

class UserImageAssetUpdateStrategyTests: MessagingTest {

    var sut: WireSyncEngine.UserImageAssetUpdateStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var updateStatus: MockImageUpdateStatus!

    override func setUp() {
        super.setUp()
        self.mockApplicationStatus = MockApplicationStatus()
        self.mockApplicationStatus.mockSynchronizationState = .online
        self.updateStatus = MockImageUpdateStatus()

        sut = self.syncMOC.performAndWait {
            UserImageAssetUpdateStrategy(managedObjectContext: self.syncMOC,
                                         applicationStatus: mockApplicationStatus,
                                         imageUploadStatus: updateStatus)
        }

        let cache = UserImageLocalCache(location: nil)
        syncMOC.performAndWait {
            self.syncMOC.zm_userImageCache = cache
        }
        uiMOC.performAndWait {
            self.uiMOC.zm_userImageCache = cache
        }
    }

    override func tearDown() {
        self.mockApplicationStatus = nil
        self.updateStatus = nil
        self.sut = nil
        syncMOC.performAndWait {
            self.syncMOC.zm_userImageCache = nil
        }
        BackendInfo.domain = nil
        super.tearDown()
    }

    // MARK: - Profile image upload

    func testThatItDoesNotReturnARequestWhenThereIsNoImageToUpload() {
        // WHEN
        updateStatus.dataToConsume.removeAll()

        // THEN
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItDoesNotReturnARequestWhenUserIsNotLoggedIn() {
        // WHEN
        updateStatus.dataToConsume[.preview] = Data()
        updateStatus.dataToConsume[.complete] = Data()
        mockApplicationStatus.mockSynchronizationState = .unauthenticated

        // THEN
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItCreatesRequestSyncs() {
        XCTAssertNotNil(sut.upstreamRequestSyncs[.preview])
        XCTAssertNotNil(sut.upstreamRequestSyncs[.complete])
    }

    func testThatItReturnsCorrectSizeFromRequestSync() {
        // WHEN
        let previewSync = sut.upstreamRequestSyncs[.preview]!
        let completeSync = sut.upstreamRequestSyncs[.complete]!

        // THEN
        XCTAssertEqual(sut.size(for: previewSync), .preview)
        XCTAssertEqual(sut.size(for: completeSync), .complete)
    }

    func testThatItCreatesRequestWhenThereIsData() {
        // WHEN
        updateStatus.dataToConsume.removeAll()
        updateStatus.dataToConsume[.preview] = Data("Some".utf8)

        // THEN
        let previewRequest = sut.nextRequest(for: .v0)
        XCTAssertNotNil(previewRequest)
        XCTAssertEqual(previewRequest?.path, "/assets/v3")
        XCTAssertEqual(previewRequest?.method, .post)

        // WHEN
        updateStatus.dataToConsume.removeAll()
        updateStatus.dataToConsume[.complete] = Data("Other".utf8)

        // THEN
        let completeRequest = sut.nextRequest(for: .v0)
        XCTAssertNotNil(completeRequest)
        XCTAssertEqual(completeRequest?.path, "/assets/v3")
        XCTAssertEqual(completeRequest?.method, .post)

    }

    func testThatItCreatesRequestWithExpectedData() {
        XCTExpectFailure("this could be flaky", strict: false)
        // GIVEN
        let previewData = Data("--1--".utf8)
        let previewRequest = sut.requestFactory.upstreamRequestForAsset(withData: previewData, shareable: true, retention: .eternal, apiVersion: .v0)
        let completeData = Data("1111111".utf8)
        let completeRequest = sut.requestFactory.upstreamRequestForAsset(withData: completeData, shareable: true, retention: .eternal, apiVersion: .v0)

        // WHEN
        updateStatus.dataToConsume.removeAll()
        updateStatus.dataToConsume[.preview] = previewData

        // THEN
        XCTAssertEqual(sut.nextRequest(for: .v0)?.binaryData, previewRequest?.binaryData)

        // WHEN
        updateStatus.dataToConsume.removeAll()
        updateStatus.dataToConsume[.complete] = completeData

        // THEN
        XCTAssertEqual(sut.nextRequest(for: .v0)?.binaryData, completeRequest?.binaryData)
    }

    func testThatItCreatesDeleteRequestIfThereAreAssetsToDelete() {
        // GIVEN
        let assetId = "12344"
        let deleteRequest = ZMTransportRequest(path: "/assets/v3/\(assetId)", method: .delete, payload: nil, apiVersion: APIVersion.v0.rawValue)

        // WHEN
        updateStatus.assetIdsToDelete = [assetId]

        // THEN
        XCTAssertEqual(sut.nextRequest(for: .v0), deleteRequest)
        XCTAssert(updateStatus.assetIdsToDelete.isEmpty)
    }

    func testThatUploadMarkedAsFailedOnUnsuccessfulResponse() {
        // GIVEN
        let size = ProfileImageSize.preview
        let sync = sut.upstreamRequestSyncs[size]
        let failedResponse = ZMTransportResponse(payload: nil, httpStatus: 500, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

        // WHEN
        sut.didReceive(failedResponse, forSingleRequest: sync!)

        // THEN
        XCTAssertEqual(updateStatus.uploadFailedForSize, size)
    }

    func testThatUploadIsMarkedAsDoneAfterSuccessfulResponse() {
        // GIVEN
        let size = ProfileImageSize.preview
        let sync = sut.upstreamRequestSyncs[size]
        let assetId = "123123"
        let payload: [String: String] = ["key": assetId]
        let successResponse = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)

        // WHEN
        sut.didReceive(successResponse, forSingleRequest: sync!)

        // THEN
        XCTAssertEqual(updateStatus.uploadDoneForSize, size)
        XCTAssertEqual(updateStatus.uploadDoneWithAssetId, assetId)

    }

    // MARK: - Profile image download

    func testThatItCreatesDownstreamRequestSyncs() {
        XCTAssertNotNil(sut.downstreamRequestSyncs[.preview])
        XCTAssertNotNil(sut.downstreamRequestSyncs[.complete])
    }

    func testThatItReturnsCorrectSizeFromDownstreamRequestSync() {
        // WHEN
        let previewSync = sut.downstreamRequestSyncs[.preview]!
        let completeSync = sut.downstreamRequestSyncs[.complete]!

        // THEN
        XCTAssertEqual(sut.size(for: previewSync), .preview)
        XCTAssertEqual(sut.size(for: completeSync), .complete)
    }

    func testThatItWhitelistsUserOnPreviewSyncForPreviewImageNotification() {
        // GIVEN
        let user = syncMOC.performAndWait {
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.previewProfileAssetIdentifier = "fooo"
            return user
        }

        let sync = self.sut.downstreamRequestSyncs[.preview]!
        XCTAssertFalse(sync.hasOutstandingItems)

        syncMOC.performAndWait {
            _ = self.syncMOC.saveOrRollback()
        }

        // WHEN
        uiMOC.performGroupedBlock {
            (self.uiMOC.object(with: user.objectID) as? ZMUser)?.requestPreviewProfileImage()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(sync.hasOutstandingItems)
    }

    func testThatItWhitelistsUserOnPreviewSyncForCompleteImageNotification() {
        // GIVEN
        let user = syncMOC.performAndWait {
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.completeProfileAssetIdentifier = "fooo"
            return user
        }

        let sync = self.sut.downstreamRequestSyncs[.complete]!
        XCTAssertFalse(sync.hasOutstandingItems)

        syncMOC.performAndWait {
            _ = self.syncMOC.saveOrRollback()
        }

        // WHEN
        uiMOC.performGroupedBlock {
            (self.uiMOC.object(with: user.objectID) as? ZMUser)?.requestCompleteProfileImage()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(sync.hasOutstandingItems)
    }

    func testThatItCreatesRequestForCorrectAssetIdentifier(for size: ProfileImageSize, apiVersion: APIVersion) throws {
        // GIVEN
        let domain = "example.domain.com"
        BackendInfo.domain = domain
        let assetId = "foo-bar"

        let userObjectId = try syncMOC.performAndWait {
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)

            switch size {
            case .preview:
                user.previewProfileAssetIdentifier = assetId
            case .complete:
                user.completeProfileAssetIdentifier = assetId
            }

            self.syncMOC.saveOrRollback()
            return try XCTUnwrap(user.objectID)
        }
        // WHEN
        uiMOC.performGroupedBlock {
            let user = self.uiMOC.object(with: userObjectId) as? ZMUser

            switch size {
            case .preview:
                user?.requestPreviewProfileImage()
            case .complete:
                user?.requestCompleteProfileImage()
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        let expectedPath: String
        switch apiVersion {
        case .v0:
            expectedPath = "/assets/v3/\(assetId)"
        case .v1:
            expectedPath = "/v1/assets/v4/\(domain)/\(assetId)"
        case .v2, .v3, .v4, .v5, .v6:
            expectedPath = "/v\(apiVersion.rawValue)/assets/\(domain)/\(assetId)"
        }

        self.syncMOC.performAndWait {
            let request = self.sut.downstreamRequestSyncs[size]?.nextRequest(for: apiVersion)
            XCTAssertNotNil(request)
            XCTAssertEqual(request?.path, expectedPath)
            XCTAssertEqual(request?.method, .get)
        }
    }

    func testThatItCreatesRequestForCorrectAssetIdentifierForPreviewImage() throws {
        try testThatItCreatesRequestForCorrectAssetIdentifier(for: .preview, apiVersion: .v0)
        try testThatItCreatesRequestForCorrectAssetIdentifier(for: .preview, apiVersion: .v1)
        try testThatItCreatesRequestForCorrectAssetIdentifier(for: .preview, apiVersion: .v2)
    }

    func testThatItCreatesRequestForCorrectAssetIdentifierForCompleteImage() throws {
        try testThatItCreatesRequestForCorrectAssetIdentifier(for: .complete, apiVersion: .v0)
        try testThatItCreatesRequestForCorrectAssetIdentifier(for: .complete, apiVersion: .v1)
        try testThatItCreatesRequestForCorrectAssetIdentifier(for: .complete, apiVersion: .v2)
    }

    func testThatItUpdatesCorrectUserImageDataForPreviewImage() throws {
        try syncMOC.performAndWait {
            // GIVEN
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            let imageData = try XCTUnwrap(Data("image".utf8))
            let sync = try XCTUnwrap(self.sut.downstreamRequestSyncs[.preview])
            user.previewProfileAssetIdentifier = "foo"
            let response = ZMTransportResponse(imageData: imageData, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            self.sut.update(user, with: response, downstreamSync: sync)

            // THEN
            XCTAssertEqual(user.imageSmallProfileData, imageData)
        }
    }

    func testThatItUpdatesCorrectUserImageDataForCompleteImage() throws {
        try syncMOC.performAndWait {
            // GIVEN
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            let imageData = try XCTUnwrap(Data("image".utf8))
            let sync = try XCTUnwrap(self.sut.downstreamRequestSyncs[.complete])
            user.completeProfileAssetIdentifier = "foo"
            let response = ZMTransportResponse(imageData: imageData, httpStatus: 200, transportSessionError: nil, headers: nil, apiVersion: APIVersion.v0.rawValue)

            // WHEN
            self.sut.update(user, with: response, downstreamSync: sync)

            // THEN
            XCTAssertEqual(user.imageMediumData, imageData)
        }
    }

    func testThatItDeletesPreviewProfileAssetIdentifierWhenReceivingAPermanentErrorForPreviewImage() {
        // Given
        let assetId = UUID.create().transportString()

        let user = syncMOC.performAndWait {
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.previewProfileAssetIdentifier = assetId
            syncMOC.saveOrRollback()
            return user
        }
        // When
        uiMOC.performGroupedBlock {
            (self.uiMOC.object(with: user.objectID) as? ZMUser)?.requestPreviewProfileImage()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        syncMOC.performAndWait {
            guard let request = sut.nextRequestIfAllowed(for: .v0) else { return XCTFail("nil request generated") }
            XCTAssertEqual(request.path, "/assets/v3/\(assetId)")
            XCTAssertEqual(request.method, .get)

            // Given
            let response = ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            request.complete(with: response)

            // THEN
            user.requestPreviewProfileImage()
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        syncMOC.performAndWait {
            XCTAssertNil(user.previewProfileAssetIdentifier)
            XCTAssertNil(sut.nextRequestIfAllowed(for: .v0))
        }
    }

    func testThatItDeletesCompleteProfileAssetIdentifierWhenReceivingAPermanentErrorForCompleteImage() {
        // Given
        let assetId = UUID.create().transportString()
        let user = syncMOC.performAndWait {
            let user = ZMUser.fetchOrCreate(with: UUID.create(), domain: nil, in: self.syncMOC)
            user.completeProfileAssetIdentifier = assetId
            syncMOC.saveOrRollback()
            return user
        }

        // When
        uiMOC.performGroupedBlock {
            (self.uiMOC.object(with: user.objectID) as? ZMUser)?.requestCompleteProfileImage()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        syncMOC.performAndWait {
            guard let request = sut.nextRequestIfAllowed(for: .v0) else { return XCTFail("nil request generated") }
            XCTAssertEqual(request.path, "/assets/v3/\(assetId)")
            XCTAssertEqual(request.method, .get)

            // Given
            let response = ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: APIVersion.v0.rawValue)
            request.complete(with: response)

            // THEN
            user.requestCompleteProfileImage()
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performAndWait {
            XCTAssertNil(user.completeProfileAssetIdentifier)
            XCTAssertNil(sut.nextRequestIfAllowed(for: .v0))
        }
    }

}
