//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

// MARK: - Modified keys for profile picture upload
extension ZMUserTests {
    func testThatSettingUserProfileAssetIdentifiersDirectlyDoesNotMarkAsModified() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)
        
        // WHEN
        user.previewProfileAssetIdentifier = "foo"
        user.completeProfileAssetIdentifier = "bar"

        // THEN
        XCTAssertFalse(user.hasLocalModifications(forKey: #keyPath(ZMUser.previewProfileAssetIdentifier)))
        XCTAssertFalse(user.hasLocalModifications(forKey: #keyPath(ZMUser.completeProfileAssetIdentifier)))
    }

    
    func testThatSettingUserProfileAssetIdentifiersMarksKeysAsModified() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)
        
        // WHEN
        user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: "foo", completeIdentifier: "bar")
        
        // THEN
        XCTAssert(user.hasLocalModifications(forKey: #keyPath(ZMUser.previewProfileAssetIdentifier)))
        XCTAssert(user.hasLocalModifications(forKey: #keyPath(ZMUser.completeProfileAssetIdentifier)))
    }
    
    func testThatSettingUserProfileAssetIdentifiersDoNothingForNonSelfUsers() {
        // GIVEN
        let initialPreview = "123456"
        let initialComplete = "987654"
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.previewProfileAssetIdentifier = initialPreview
        user.completeProfileAssetIdentifier = initialComplete
        
        // WHEN
        user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: "foo", completeIdentifier: "bar")
        
        // THEN
        XCTAssertEqual(user.previewProfileAssetIdentifier, initialPreview)
        XCTAssertEqual(user.completeProfileAssetIdentifier, initialComplete)
    }
    
}

// MARK: - AssetV3 response parsing

extension ZMUserTests {
    
    func assetPayload(previewId: String , completeId: String) -> NSArray {
        return [
            ["size" : "preview", "type" : "image", "key" : previewId],
            ["size" : "complete", "type" : "image", "key" : completeId],
        ] as NSArray
    }
    
    func testThatItDoesNotUpdateAssetsWhenThereAreLocalModifications() {
        syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let user = ZMUser.selfUser(in: self.syncMOC)
            let previewId = "some"
            let completeId = "other"
            let payload = self.assetPayload(previewId: "foo", completeId: "bar")
            
            // WHEN
            user.updateAndSyncProfileAssetIdentifiers(previewIdentifier: previewId, completeIdentifier: completeId)
            user.updateAssetData(with: payload, hasLegacyImages:false, authoritative: true)
            
            // THEN
            XCTAssertEqual(user.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(user.completeProfileAssetIdentifier, completeId)
        }
    }
    
    func testThatItRemovesRemoteIdentifiersWhenWeGetEmptyAssets() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.previewProfileAssetIdentifier = "some"
            user?.completeProfileAssetIdentifier = "other"
            
            // WHEN
            user?.updateAssetData(with: NSArray(), hasLegacyImages:false, authoritative: true)
            
            // THEN
            XCTAssertNil(user?.previewProfileAssetIdentifier)
            XCTAssertNil(user?.completeProfileAssetIdentifier)
        }
    }
    
    func testThatItUpdatesIdentifiersAndRemovesCachedImagesWhenWeGetRemoteIdentifiers() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.previewProfileAssetIdentifier = "123"
            user?.completeProfileAssetIdentifier = "456"
            user?.imageSmallProfileData = "some".data(using: .utf8)
            user?.imageMediumData = "other".data(using: .utf8)
            XCTAssertNotNil(user?.imageMediumData)
            XCTAssertNotNil(user?.imageSmallProfileData)
            let previewId = "some"
            let completeId = "other"
            let payload = self.assetPayload(previewId: previewId, completeId: completeId)
            
            // WHEN
            user?.updateAssetData(with: payload, hasLegacyImages:false, authoritative: true)
            
            // THEN
            XCTAssertEqual(user?.previewProfileAssetIdentifier, previewId)
            XCTAssertNil(user?.imageSmallProfileData)
            XCTAssertEqual(user?.completeProfileAssetIdentifier, completeId)
            XCTAssertNil(user?.imageMediumData)
        }
    }
    
    func testThatItDoesNotRemoveLocalImagesIfRemoteIdentifiersHaveNotChanged() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let previewId = "some"
            let previewData = "some".data(using: .utf8)
            let completeId = "other"
            let completeData = "other".data(using: .utf8)
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.previewProfileAssetIdentifier = previewId
            user?.completeProfileAssetIdentifier = completeId
            user?.imageSmallProfileData = previewData
            user?.imageMediumData = completeData
            XCTAssertNotNil(user?.imageMediumData)
            XCTAssertNotNil(user?.imageSmallProfileData)
            let payload = self.assetPayload(previewId: previewId, completeId: completeId)
            
            // WHEN
            user?.updateAssetData(with: payload, hasLegacyImages:false, authoritative: true)
            
            // THEN
            XCTAssertEqual(user?.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(user?.imageSmallProfileData, previewData)
            XCTAssertEqual(user?.completeProfileAssetIdentifier, completeId)
            XCTAssertEqual(user?.imageMediumData, completeData)
        }
    }

}

// MARK: - AssetV3 filter predicates
extension ZMUserTests {
    func testThatPreviewImageDownloadFilterPicksUpUser() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.previewImageDownloadFilter
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.previewProfileAssetIdentifier = "some identifier"
            user?.imageSmallProfileData = nil
            
            // THEN
            XCTAssert(predicate.evaluate(with: user))
        }
    }
    
    func testThatCompleteImageDownloadFilterPicksUpUser() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.completeProfileAssetIdentifier = "some identifier"
            user?.imageMediumData = nil
            
            // THEN
            XCTAssert(predicate.evaluate(with: user))
        }
    }
    
    func testThatPreviewImageDownloadFilterDoesNotPickUpUsersWithoutAssetId() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.previewImageDownloadFilter
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.previewProfileAssetIdentifier = nil
            user?.imageSmallProfileData = "foo".data(using: .utf8)
            
            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }
    
    func testThatCompleteImageDownloadFilterDoesNotPickUpUsersWithoutAssetId() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.completeProfileAssetIdentifier = nil
            user?.imageMediumData = "foo".data(using: .utf8)
            
            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }
    
    func testThatPreviewImageDownloadFilterDoesNotPickUpUsersWithCachedImages() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.previewProfileAssetIdentifier = "1234"
            user?.imageSmallProfileData = "foo".data(using: .utf8)
            
            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }
    
    func testThatCompleteImageDownloadFilterDoesNotPickUpUsersWithCachedImages() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.completeProfileAssetIdentifier = "1234"
            user?.imageMediumData = "foo".data(using: .utf8)
            
            // THEN
            XCTAssertFalse(predicate.evaluate(with: user))
        }
    }
}

// MARK: - AssetV3 request notifications
extension ZMUserTests {
    
    func testThatItPostsPreviewRequestNotifications() {
        let noteExpectation = expectation(description: "PreviewAssetFetchNotification should be fired")
        var userObjectId: NSManagedObjectID? = nil
        
        let note = NotificationCenterObserverToken(name: ZMUser.previewAssetFetchNotification) { note in
            let objectId = note.object as? NSManagedObjectID
            XCTAssertNotNil(objectId)
            XCTAssertEqual(objectId, userObjectId)
            noteExpectation.fulfill()
        }

        syncMOC.performGroupedBlock {
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            userObjectId = user?.objectID
            user?.requestPreviewAsset()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        _ = note // Silence warning
    }
    
    func testThatItPostsCompleteRequestNotifications() {
        let noteExpectation = expectation(description: "CompleteAssetFetchNotification should be fired")
        var userObjectId: NSManagedObjectID? = nil
        
        let note = NotificationCenterObserverToken(name: ZMUser.completeAssetFetchNotification) { note in
            let objectId = note.object as? NSManagedObjectID
            XCTAssertNotNil(objectId)
            XCTAssertEqual(objectId, userObjectId)
            noteExpectation.fulfill()
        }
        
        syncMOC.performGroupedBlock {
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            userObjectId = user?.objectID
            user?.requestCompleteAsset()
        }
        
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        _ = note // Silence warning
    }
}
