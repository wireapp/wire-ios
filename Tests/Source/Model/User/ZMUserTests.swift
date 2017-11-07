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
    
    func testThatItIgnoreAssetsWithIllegalCharacters() {
        syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let user = ZMUser.selfUser(in: self.syncMOC)
            let previewId = "some"
            let completeId = "other"
            let payload = self.assetPayload(previewId: "Aa\\u0000\r\n", completeId: "Aa\\u0000\r\n")
            
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
        
        let token = ManagedObjectObserverToken(name: ZMUser.previewAssetFetchNotification,
                                               managedObjectContext: self.uiMOC)
        { note in
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
        
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
    
    func testThatItPostsCompleteRequestNotifications() {
        let noteExpectation = expectation(description: "CompleteAssetFetchNotification should be fired")
        var userObjectId: NSManagedObjectID? = nil
        
        let token = ManagedObjectObserverToken(name: ZMUser.completeAssetFetchNotification,
                                               managedObjectContext: self.uiMOC)
        { note in
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
        
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}

extension ZMUser {
    static func insert(in moc: NSManagedObjectContext, name: String, handle: String? = nil, connected: Bool = true) -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.name = name
        user.setHandle(handle)
        let connection = ZMConnection.insertNewSentConnection(to: user)
        if connected {
            connection?.status = .accepted
        }
        
        return user
    }
}

// MARK: - Predicates
extension ZMUserTests {
    
    func testPredicateFilteringNonBotUsers() {
        // Given
        let anna = ZMUser.insert(in: uiMOC, name: "anna", handle: ZMUser.annaBotHandle)
        let otto = ZMUser.insert(in: uiMOC, name: "otto", handle: ZMUser.ottoBotHandle)
        let user = ZMUser.insert(in: uiMOC, name: "Some one")
        let all = NSArray(array: [anna, otto, user])
        
        // When
        let nonBots = all.filtered(using: ZMUser.nonBotUsersPredicate) as! [ZMUser]
        
        // Then
        XCTAssertEqual(nonBots.count, 1)
        XCTAssertEqual(nonBots, [user])
    }
    
    func testPredicateFilteringConnectedNonBotUsers() {
        // Given
        let anna = ZMUser.insert(in: self.uiMOC, name: "anna", handle: ZMUser.annaBotHandle)
        let other = ZMUser.insert(in: self.uiMOC, name: "Nobody", handle: "no-b", connected: false)
        let user = ZMUser.insert(in: self.uiMOC, name: "Some one", handle: "yes-b", connected: true)
        let all = NSArray(array: [anna, user, other])
        
        // When
        let connectedNonBots = all.filtered(using: ZMUser.predicateForConnectedNonBotUsers) as! [ZMUser]
        
        // Then
        XCTAssertEqual(connectedNonBots.count, 1)
        XCTAssertEqual(connectedNonBots, [user])
    }
    
    func testPredicateFilteringConnectedUsers() {
        // Given
        let anna = ZMUser.insert(in: self.uiMOC, name: "anna", handle: ZMUser.annaBotHandle, connected: true)
        let connectedUser = ZMUser.insert(in: self.uiMOC, name: "Body no", handle: "no-b", connected: true)
        let user = ZMUser.insert(in: self.uiMOC, name: "Body yes", handle: "yes-b", connected: false)
        
        let all = NSArray(array: [anna, connectedUser, user])
        
        // When
        let connectedBots = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "anna")) as! [ZMUser]
        let connectedUsers = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "Body")) as! [ZMUser]

        // Then
        XCTAssertEqual(connectedBots.count, 1)
        XCTAssertEqual(connectedBots, [anna])
        XCTAssertEqual(connectedUsers.count, 1)
        XCTAssertEqual(connectedUsers, [connectedUser])
    }
    
    func testPredicateFilteringConnectedUsersByHandle() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "yyy", connected: true)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connected: true)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "yyy")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testPredicateFilteringConnectedUsersByHandleWithAtSymbol() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "ab", connected: true)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connected: true)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "@ab")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testThatThePredicateUsesTheNormalizedQueryToMatchHandlesWhenSearchingWithLeadingAtSymbol() {
        // Given
        let user1 = ZMUser.insert(in: uiMOC, name: "Teapot", handle: "vanessa", connected: true)
        let user2 = ZMUser.insert(in: uiMOC, name: "Norman", handle: "joao", connected: true)
        let users = [user1, user2] as NSArray

        // When
        let predicate = ZMUser.predicateForConnectedUsers(withSearch: "@João")
        let result = users.filtered(using: predicate) as! [ZMUser]

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result, [user2])
    }

    func testThatItStripsWhiteSpaceBeforeSearching() {
        // Given
        let user1 = ZMUser.insert(in: uiMOC, name: "Vanessa", handle: "abc", connected: true)
        let user2 = ZMUser.insert(in: uiMOC, name: "Norman", handle: "joao", connected: true)
        let users = [user1, user2] as NSArray

        do {
            // When
            let predicate = ZMUser.predicateForConnectedUsers(withSearch: "  vÂńĖß   ")
            let result = users.filtered(using: predicate) as! [ZMUser]

            // Then
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result, [user1])
        }

        do {
            // When
            let predicate = ZMUser.predicateForConnectedUsers(withSearch: "  @JOÃO   ")
            let result = users.filtered(using: predicate) as! [ZMUser]

            // Then
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result, [user2])
        }
    }

    func testPredicateFilteringConnectedUsersByHandlePrefix() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "alonghandle", connected: true)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connected: true)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "alo")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }
    
    func testPredicateFilteringConnectedUsersStripsDiactricMarks() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Šőmė body", handle: "hand", connected: true)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connected: true)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "some")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }
    
    func testPredicateFilteringForAllUsers() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "ab", connected: true)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "no-b", connected: true)
        let user3 = ZMUser.insert(in: self.uiMOC, name: "Yes body", handle: "yes-b", connected: false)

        let all = NSArray(array: [user1, user2, user3])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForAllUsers(withSearch: "body")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 3)
        XCTAssertEqual(users, [user1, user2, user3])
    }
    
}

// MARK: - Filename
extension ZMUserTests {
    
    /// check the generated filename matches several critirias and a regex pattern
    ///
    /// - Parameters:
    ///   - pattern: pattern string for regex
    ///   - filename: filename to check
    func checkFilenameIsValid(pattern: String, filename: String) {
        XCTAssertEqual(filename.count, 214)
        XCTAssertTrue(filename.hasPrefix("Some"))
        XCTAssertTrue(filename.contains("body"))

        let regexp = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regexp.matches(in: filename as String, options: [], range: NSMakeRange(0, filename.count))
        
        XCTAssertTrue(matches.count > 0)
    }
    
    func testFilenameForUser() throws {
        // Given
        let user = ZMUser.insert(in: self.uiMOC, name: "Some body with a very long name and a emoji 🇭🇰 and some Chinese 中文 and some German Fußgängerübergänge")
        
        // When
        let filename = user.filename()
        
        // Then
        /// check ends with a date stamp, e.g. -2017-10-24-11.05.43
        let pattern = "^.*[0-9-.]{20,20}$"
        checkFilenameIsValid(pattern: pattern, filename: filename)
    }

    func testFilenameWithSuffixForUser() throws {
        // Given
        let user = ZMUser.insert(in: self.uiMOC, name: "Some body with a very long name and a emoji 🇭🇰 and some Chinese 中文 and some German Fußgängerübergänge")
        
        // When
        let suffix: String = "-Jellyfish"
        let filename = user.filename(suffix: suffix)
        
        // Then
        /// check ends with a date stamp and a suffix, e.g. -2017-10-24-11.05.43-Jellyfish
        let pattern = "^.*[0-9-.]{20,20}\(suffix)$"
        checkFilenameIsValid(pattern: pattern, filename: filename)
    }
}
