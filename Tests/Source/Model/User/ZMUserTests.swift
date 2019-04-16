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
            user.updateAssetData(with: payload, authoritative: true)
            
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
            user.updateAssetData(with: payload, authoritative: true)
            
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
            user?.updateAssetData(with: NSArray(), authoritative: true)
            
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
            user?.setImage(data: "some".data(using: .utf8), size: .preview)
            user?.setImage(data: "other".data(using: .utf8), size: .complete)
            XCTAssertNotNil(user?.imageData(for: .preview))
            XCTAssertNotNil(user?.imageData(for: .complete))
            let previewId = "some"
            let completeId = "other"
            let payload = self.assetPayload(previewId: previewId, completeId: completeId)
            
            // WHEN
            user?.updateAssetData(with: payload, authoritative: true)
            
            // THEN
            XCTAssertEqual(user?.previewProfileAssetIdentifier, previewId)
            XCTAssertNil(user?.imageData(for: .preview))
            XCTAssertEqual(user?.completeProfileAssetIdentifier, completeId)
            XCTAssertNil(user?.imageData(for: .complete))
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
            user?.setImage(data: previewData, size: .preview)
            user?.setImage(data: completeData, size: .complete)
            XCTAssertNotNil(user?.imageData(for: .preview))
            XCTAssertNotNil(user?.imageData(for: .complete))
            let payload = self.assetPayload(previewId: previewId, completeId: completeId)
            
            // WHEN
            user?.updateAssetData(with: payload, authoritative: true)
            
            // THEN
            XCTAssertEqual(user?.previewProfileAssetIdentifier, previewId)
            XCTAssertEqual(user?.completeProfileAssetIdentifier, completeId)
            XCTAssertEqual(user?.imageData(for: .preview), previewData)
            XCTAssertEqual(user?.imageData(for: .complete), completeData)
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
            user?.setImage(data: nil, size: .complete)
            
            // THEN
            XCTAssert(predicate.evaluate(with: user))
        }
    }
    
    func testThatCompleteImageDownloadFilterDoesNotPickUpUsersWithoutAssetId() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let predicate = ZMUser.completeImageDownloadFilter
            let user = ZMUser(remoteID: UUID.create(), createIfNeeded: true, in: self.syncMOC)
            user?.completeProfileAssetIdentifier = nil
            user?.setImage(data: "foo".data(using: .utf8), size: .complete)
            
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
            user?.setImage(data: "foo".data(using: .utf8), size: .preview)
            
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
            user?.setImage(data: "foo".data(using: .utf8), size: .complete)
            
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
        
        let token = ManagedObjectObserverToken(name: .userDidRequestPreviewAsset,
                                               managedObjectContext: self.uiMOC)
        { note in
            let objectId = note.object as? NSManagedObjectID
            XCTAssertNotNil(objectId)
            XCTAssertEqual(objectId, userObjectId)
            noteExpectation.fulfill()
        }

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        userObjectId = user.objectID
        user.requestPreviewProfileImage()
        
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
    
    func testThatItPostsCompleteRequestNotifications() {
        let noteExpectation = expectation(description: "CompleteAssetFetchNotification should be fired")
        var userObjectId: NSManagedObjectID? = nil
        
        let token = ManagedObjectObserverToken(name: .userDidRequestCompleteAsset,
                                               managedObjectContext: self.uiMOC)
        { note in
            let objectId = note.object as? NSManagedObjectID
            XCTAssertNotNil(objectId)
            XCTAssertEqual(objectId, userObjectId)
            noteExpectation.fulfill()
        }
        
        let user =  ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = UUID.create()
        userObjectId = user.objectID
        user.requestCompleteProfileImage()
        
        withExtendedLifetime(token) { () -> () in
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        }
    }
}

extension ZMUser {
    static func insert(in moc: NSManagedObjectContext, name: String, handle: String? = nil, connectionStatus: ZMConnectionStatus = .accepted) -> ZMUser {
        let user = ZMUser.insertNewObject(in: moc)
        user.name = name
        user.setHandle(handle)
        let connection = ZMConnection.insertNewSentConnection(to: user)
        connection?.status = connectionStatus
        
        return user
    }
}

// MARK: - Predicates
extension ZMUserTests {
    
    func testPredicateFilteringConnectedUsersByHandle() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "yyy", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "yyy")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testPredicateFilteringConnectedUsersByHandleWithAtSymbol() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "ab", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "@ab")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }

    func testPredicateFilteringConnectedUsersByHandlePrefix() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "alonghandle", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "alo")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }
    
    func testPredicateFilteringConnectedUsersStripsDiactricMarks() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Šőmė body", handle: "hand", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "yes-b", connectionStatus: .accepted)
        
        let all = NSArray(array: [user1, user2])
        
        // When
        let users = all.filtered(using: ZMUser.predicateForConnectedUsers(withSearch: "some")) as! [ZMUser]
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users, [user1])
    }
    
    func testPredicateFilteringForAllUsers() {
        // Given
        let user1 = ZMUser.insert(in: self.uiMOC, name: "Some body", handle: "ab", connectionStatus: .accepted)
        let user2 = ZMUser.insert(in: self.uiMOC, name: "No body", handle: "no-b", connectionStatus: .accepted)
        let user3 = ZMUser.insert(in: self.uiMOC, name: "Yes body", handle: "yes-b", connectionStatus: .pending)

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

// MARK: - Availability
extension ZMUserTests {
    
    func testThatWeCanUpdateAvailabilityFromGenericMessage() {
        let user = ZMUser.insert(in: self.uiMOC, name: "Foo")
        XCTAssertEqual(user.availability, .none)
                
        // when
        user.updateAvailability(from: ZMGenericMessage.message(content: ZMAvailability.availability(.away)))
        
        // then
        XCTAssertEqual(user.availability, .away)
    }
    
    func testThatWeAllowModifyingAvailabilityOnTheSelfUser() {
        // given
        XCTAssertEqual(selfUser.availability, .none)
        
        // when
        selfUser.availability = .away
        
        // then
        XCTAssertEqual(selfUser.availability, .away)
    }
    
    func testThatWeDontAllowModifyingAvailabilityOnOtherUsers() {
        // given
        let user = ZMUser.insert(in: self.uiMOC, name: "Foo")
        XCTAssertEqual(user.availability, .none)
        
        // when
        user.availability = .away
        
        // then
        XCTAssertEqual(user.availability, .none)
    }
    
    func testThatConnectionsAndTeamMembersReturnsExpectedUsers() {
        // given
        _ = ZMUser.insert(in: uiMOC, name: "user1", handle: "handl1", connectionStatus: .pending)
        _ = ZMUser.insert(in: uiMOC, name: "user2", handle: "handl1", connectionStatus: .blocked)
        _ = ZMUser.insert(in: uiMOC, name: "user3", handle: "handl1", connectionStatus: .cancelled)
        _ = ZMUser.insert(in: uiMOC, name: "user4", handle: "handl1", connectionStatus: .ignored)
        _ = ZMUser.insert(in: uiMOC, name: "user5", handle: "handl1", connectionStatus: .sent)
        _ = ZMUser.insert(in: uiMOC, name: "user6", handle: "handl1", connectionStatus: .invalid)
        let connectedUser = ZMUser.insert(in: uiMOC, name: "user7", handle: "handl1", connectionStatus: .accepted)
        let connectedUserWithoutHandle = ZMUser.insert(in: uiMOC, name: "user8", handle: nil, connectionStatus: .accepted)
        
        let team = Team.insertNewObject(in: uiMOC)
        let teamUser = ZMUser.insertNewObject(in: uiMOC)
        teamUser.remoteIdentifier = .create()
        
        let membership = Member.insertNewObject(in: uiMOC)
        membership.team = team
        membership.user = teamUser
        membership.remoteIdentifier = teamUser.remoteIdentifier
        
        let selfMembership = Member.insertNewObject(in: uiMOC)
        selfMembership.team = team
        selfMembership.user = selfUser
        selfMembership.remoteIdentifier = selfUser.remoteIdentifier
        
        // when
        let connectionsAndTeamMembers = ZMUser.connectionsAndTeamMembers(in: uiMOC)

        // then
        XCTAssertEqual(Set<ZMUser>(arrayLiteral: connectedUser, connectedUserWithoutHandle, teamUser, selfUser), connectionsAndTeamMembers)
    }
    
    func testThatNeedsToNotifyAvailabilityBehaviourChangeDefaultsToNothing() {
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, [])
    }
    
    func testThatNeedsToNotifyAvailabilityBehaviourChangeCanBeUpdated() {
        // given
        selfUser.needsToNotifyAvailabilityBehaviourChange = .alert
        
        // then
        XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, .alert)
    }
        
}

// MARK: - Bot support
extension ZMUserTests {
    func testThatServiceIdentifierAndProviderIdentifierAreNilByDefault() {
        // GIVEN
        let sut = ZMUser.insertNewObject(in: self.uiMOC)

        // WHEN & THEN
        XCTAssertNil(sut.providerIdentifier)
        XCTAssertNil(sut.serviceIdentifier)
    }
}

// MARK: - Expiration support
extension ZMUserTests {
    func testIsWirelessUserCalculation_false() {
        // given
        let sut = ZMUser.insertNewObject(in: self.uiMOC)
        // when & then
        XCTAssertFalse(sut.isWirelessUser)
        XCTAssertFalse(sut.isExpired)
        XCTAssertEqual(sut.expiresAfter, 0)
    }
    
    func testIsWirelessUserCalculation_true_not_expired() {
        // given
        let sut = ZMUser.insertNewObject(in: self.uiMOC)
        sut.expiresAt = Date(timeIntervalSinceNow: 1)
        // when & then
        XCTAssertTrue(sut.isWirelessUser)
        XCTAssertFalse(sut.isExpired)
        XCTAssertEqual(round(sut.expiresAfter), 1)
    }
    
    func testIsWirelessUserCalculation_true_expired() {
        // given
        let sut = ZMUser.insertNewObject(in: self.uiMOC)
        sut.expiresAt = Date(timeIntervalSinceNow: -1)
        // when & then
        XCTAssertTrue(sut.isWirelessUser)
        XCTAssertTrue(sut.isExpired)
        XCTAssertEqual(round(sut.expiresAfter), 0)
    }
}

// MARK: - Account deletion

extension ZMUserTests {
    
    func testThatUserIsRemovedFromAllConversationsWhenAccountIsDeleted() {
        // given
        let sut = createUser(in: uiMOC)
        let conversation1 = createConversation(in: uiMOC)
        conversation1.conversationType = .group
        conversation1.mutableLastServerSyncedActiveParticipants.add(sut)
        
        let conversation2 = createConversation(in: uiMOC)
        conversation2.conversationType = .group
        conversation2.mutableLastServerSyncedActiveParticipants.add(sut)
        
        // when
        sut.markAccountAsDeleted(at: Date())
        
        // then
        XCTAssertFalse(conversation1.lastServerSyncedActiveParticipants.contains(sut))
        XCTAssertFalse(conversation2.lastServerSyncedActiveParticipants.contains(sut))
    }
    
    func testThatUserIsNotRemovedFromTeamOneToOneConversationsWhenAccountIsDeleted() {
        // given
        let team = createTeam(in: uiMOC)
        let sut = createTeamMember(in: uiMOC, for: team)
        let teamOneToOneConversation = ZMConversation.fetchOrCreateTeamConversation(in: uiMOC, withParticipant: sut, team: team)!
        teamOneToOneConversation.teamRemoteIdentifier = team.remoteIdentifier
        
        // when
        sut.markAccountAsDeleted(at: Date())
        
        // then
        XCTAssertTrue(teamOneToOneConversation.lastServerSyncedActiveParticipants.contains(sut))
    }
    
}

// MARK: - Active conversations

extension ZMUserTests {
    
    func testActiveConversationsForSelfUser() {
        // given
        let sut = ZMUser.selfUser(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.isSelfAnActiveMember = true
        
        // then
        XCTAssertEqual(sut.activeConversations, Set(arrayLiteral: conversation))
    }
    
    func testActiveConversationsForOtherUser() {
        // given
        let sut = ZMUser.insertNewObject(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mutableLastServerSyncedActiveParticipants.add(sut)
        
        // then
        XCTAssertEqual(sut.activeConversations, Set(arrayLiteral: conversation))
    }
    
}

// MARK: - Self user tests
extension ZMUserTests {
    func testThatItIsPossibleToSetReadReceiptsEnabled() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        // WHEN
        sut.readReceiptsEnabled = true
        // THEN
        XCTAssertEqual(sut.readReceiptsEnabled, true)
    }
    
    func testThatItIsPossibleToSetReadReceiptsEnabled_andReset() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        // WHEN
        sut.readReceiptsEnabled = true
        // THEN
        XCTAssertEqual(sut.readReceiptsEnabled, true)
        // AND WHEN
        sut.readReceiptsEnabled = false
        // THEN
        XCTAssertEqual(sut.readReceiptsEnabled, false)
    }
    
    func testThatItUpdatesOtherContextForEnableReadReceipts() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        // WHEN
        sut.readReceiptsEnabled = true
        self.uiMOC.saveOrRollback()
        
        // THEN
        
        self.syncMOC.performGroupedBlock {
            let syncSelfUser = ZMUser.selfUser(in: self.syncMOC)

            XCTAssertEqual(syncSelfUser.readReceiptsEnabled, true)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testThatItSetsModifiedKeysForEnableReadReceipts() {
        // GIVEN
        let sut = ZMUser.selfUser(in: uiMOC)
        sut.resetLocallyModifiedKeys(Set())
        
        // WHEN
        sut.readReceiptsEnabled = true
        
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(sut.modifiedKeys, Set([ReadReceiptsEnabledKey]))
    }
    
    func testThatItDoesNotSetModifiedKeysForEnableReadReceipts() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let sut = ZMUser.selfUser(in: self.syncMOC)
            sut.resetLocallyModifiedKeys(Set())
            
            // WHEN
            sut.readReceiptsEnabled = true
            self.syncMOC.saveOrRollback()

            // THEN
            XCTAssertEqual(sut.modifiedKeys, nil)
        }
    }
    
    func testThatItSavesValueOfReadReceiptsEnabled() {
        // GIVEN
        let user = ZMUser.selfUser(in: uiMOC)
        // WHEN
        user.readReceiptsEnabled = true
        uiMOC.saveOrRollback()
        // THEN
        XCTAssert(user.readReceiptsEnabled)
    }
}

