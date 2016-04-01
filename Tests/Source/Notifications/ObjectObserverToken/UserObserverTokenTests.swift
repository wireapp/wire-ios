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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
@testable import zmessaging

extension NSManagedObject {
    func changedKeys() -> Set<String> {
        var result : [String] = []
        for key in self.changedValues().keys {
            result.append(key as String)
        }
        return Set(result)
    }
}

class UserObserverTokenTests : MessagingTest {
    
    let UserClientsKey = "clients"

    enum UserInfoChangeKey: String {
        case Name = "nameChanged"
        case AccentColor = "accentColorValueChanged"
        case ImageMediumData = "imageMediumDataChanged"
        case ImageSmallProfileData = "imageSmallProfileDataChanged"
        case ProfileInfo = "profileInformationChanged"
        case ConnectionState = "connectionStateChanged"
        case TrustLevel = "trustLevelChanged"
    }

    let userInfoChangeKeys: [UserInfoChangeKey] = [
        .Name,
        .AccentColor,
        .ImageMediumData,
        .ImageSmallProfileData,
        .ProfileInfo,
        .ConnectionState,
        .TrustLevel
    ]
    
    override func setUp() {
        super.setUp()
        self.uiMOC.globalManagedObjectContextObserver.syncCompleted(NSNotification(name: "fake", object: nil))
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }

    func checkThatItNotifiesTheObserverOfAChange(user : ZMUser, modifier: ZMUser -> Void, expectedChangedField: UserInfoChangeKey, customAffectedKeys: AffectedKeys? = nil) {

        // given
        let observer = TestUserObserver()
        let token = ZMUser.addUserObserver(observer, forUsers: [user], managedObjectContext: user.managedObjectContext)
        self.uiMOC.saveOrRollback()

        // when
        modifier(user)
        self.uiMOC.saveOrRollback()

        // then
        let changeCount = observer.receivedChangeInfo.count
        XCTAssertEqual(changeCount, 1)

        // and when
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, changeCount, "Should not have changed further once")

        if let changes = observer.receivedChangeInfo.firstObject as? UserChangeInfo {
            for key in userInfoChangeKeys where key != expectedChangedField  {
                if let value = changes.valueForKey(key.rawValue) as? NSNumber {
                    XCTAssertFalse(value.boolValue, "\(key.rawValue) was supposed to be false")
                }
                else {
                    XCTFail("Can't find key or key is not boolean for '\(key.rawValue)'")
                }
            }
        }
        ZMUser.removeUserObserverForToken(token)
    }


    func testThatItNotifiesTheObserverOfANameChange()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.name = "George"
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier: { $0.name = "Phil"},
            expectedChangedField: .Name)

    }

    func testThatItNotifiestheObserverOfMultipleNameChanges()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        let observer = TestUserObserver()
        let token = ZMUser.addUserObserver(observer, forUsers: [user], managedObjectContext: user.managedObjectContext)
        self.uiMOC.saveOrRollback()

        // when
        user.name = "Foo"
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)

        // and when
        user.name = "Bar"
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 2)

        // and when
        self.uiMOC.saveOrRollback()
        ZMUser.removeUserObserverForToken(token)

        ZMUser.removeUserObserverForToken(token)
    }

    func testThatItNotifiesTheObserverOfAnAccentColorChange()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.accentColorValue = ZMAccentColor.StrongBlue

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier: { $0.accentColorValue = ZMAccentColor.SoftPink },
            expectedChangedField: .AccentColor)

    }

    func testThatItNotifiesTheObserverOfAMediumProfileImageChange()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.remoteIdentifier = NSUUID.createUUID()
        user.mediumRemoteIdentifier = NSUUID.createUUID()
        user.imageMediumData = self.verySmallJPEGData()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier: { $0.imageMediumData = NSData() },
            expectedChangedField: .ImageMediumData)
    }

    func testThatItNotifiesTheObserverOfASmallProfileImageChange()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.remoteIdentifier = NSUUID.createUUID()
        user.smallProfileRemoteIdentifier = NSUUID.createUUID()
        user.imageSmallProfileData = self.verySmallJPEGData()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier: { $0.imageSmallProfileData = NSData() },
            expectedChangedField: .ImageSmallProfileData)
    }

    func testThatItNotifiesTheObserverOfAnEmailChange()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.setEmailAddress("foo@example.com", onUser: user)

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier: { self.setEmailAddress(nil, onUser: $0) },
            expectedChangedField: .ProfileInfo)
    }

    func testThatItNotifiesTheObserverOfAPhoneNumberChange()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.setPhoneNumber("+99-32312423423", onUser: user)


        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier: { self.setPhoneNumber("+99-0000", onUser: $0) },
            expectedChangedField: .ProfileInfo)
    }

    func testThatItNotifiesTheObserverOfAConnectionStateChange()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.connection!.status = ZMConnectionStatus.Pending
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier : { $0.connection!.status = ZMConnectionStatus.Accepted },
            expectedChangedField: .ConnectionState,
            customAffectedKeys: AffectedKeys.All)
    }

    func testThatItNotifiesTheObserverOfACreatedIncomingConnection()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier : {
                $0.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
                $0.connection!.status = ZMConnectionStatus.Pending
            },
            expectedChangedField: .ConnectionState,
            customAffectedKeys: AffectedKeys.All)
    }

    func testThatItNotifiesTheObserverOfACreatedOutgoingConnection()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(user,
            modifier : {
                $0.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
                $0.connection!.status = ZMConnectionStatus.Sent
            },
            expectedChangedField: .ConnectionState,
            customAffectedKeys: AffectedKeys.All)
    }

    func testThatItStopsNotifyingAfterUnregisteringTheToken() {

        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.setEmailAddress("foo@example.com", onUser: user)
        self.uiMOC.saveOrRollback()

        let observer = TestUserObserver()
        let token = ZMUser.addUserObserver(observer, forUsers: [user], managedObjectContext: self.uiMOC)
        ZMUser.removeUserObserverForToken(token)


        // when
        user.emailAddress = "aaaaaa@example.com"
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 0)
    }

    func testThatItNotifiesUserForClientStartsTrusting() {

        // given
        let user = ZMUser.selfUserInContext(self.uiMOC)
        let client = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.mutableSetValueForKey(UserClientsKey).addObject(client)
        otherUser.mutableSetValueForKey(UserClientsKey).addObject(otherClient)

        // when
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        self.checkThatItNotifiesTheObserverOfAChange(otherUser,
            modifier: { _ in client.trustClient(otherClient) },
            expectedChangedField: .TrustLevel)

        XCTAssertTrue(otherClient.trustedByClients.contains(client))
    }

    func testThatItNotifiesUserForClientStartsIgnoring() {

        // given
        let user = ZMUser.selfUserInContext(self.uiMOC)
        let client = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.mutableSetValueForKey(UserClientsKey).addObject(client)
        otherUser.mutableSetValueForKey(UserClientsKey).addObject(otherClient)

        // when
        client.trustClient(otherClient)
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        self.checkThatItNotifiesTheObserverOfAChange(otherUser,
            modifier: { _ in client.ignoreClient(otherClient) },
            expectedChangedField: .TrustLevel)

        XCTAssertFalse(otherClient.trustedByClients.contains(client))
        XCTAssertTrue(otherClient.ignoredByClients.contains(client))
    }

    func testThatItUpdatesClientObserversWhenClientIsAdded() {

        // given
        let observer = TestUserObserver()
        let selfUser = ZMUser.selfUserInContext(self.uiMOC)
        let selfClient = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        selfUser.mutableSetValueForKey(UserClientsKey).addObject(selfClient)
        let token = ZMUser.addUserObserver(observer, forUsers: [selfUser], managedObjectContext: selfUser.managedObjectContext)
        self.uiMOC.saveOrRollback()

        // when
        let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        selfUser.mutableSetValueForKey(UserClientsKey).addObject(otherClient)
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        guard let changeInfo = observer.receivedChangeInfo.firstObject as? UserChangeInfo else { return XCTFail("Should receive a changeInfo for the added client") }
        XCTAssertTrue(changeInfo.clientsChanged)
        XCTAssertTrue(changeInfo.changedKeysAndOldValues.keys.contains(UserClientsKey))

        // after
        ZMUser.removeUserObserverForToken(token)
    }


    func testThatItUpdatesClientObserversWhenClientIsRemoved() {

        // given
        let observer = TestUserObserver()
        let selfUser = ZMUser.selfUserInContext(self.uiMOC)
        let selfClient = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        let otherClient = UserClient.insertNewObjectInManagedObjectContext(self.uiMOC)
        selfUser.mutableSetValueForKey(UserClientsKey).addObject(selfClient)
        selfUser.mutableSetValueForKey(UserClientsKey).addObject(otherClient)
        let token = ZMUser.addUserObserver(observer, forUsers: [selfUser], managedObjectContext: selfUser.managedObjectContext)
        self.uiMOC.saveOrRollback()
        XCTAssertEqual(selfUser.clients.count, 2)

        // when
        selfUser.mutableSetValueForKey(UserClientsKey).removeObject(otherClient)
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        guard let changeInfo = observer.receivedChangeInfo.firstObject as? UserChangeInfo else { return XCTFail("Should receive a changeInfo for the added client") }
        XCTAssertTrue(changeInfo.clientsChanged)
        XCTAssertTrue(changeInfo.changedKeysAndOldValues.keys.contains(UserClientsKey))
        XCTAssertEqual(selfUser.clients, Set(arrayLiteral: selfClient))
        XCTAssertEqual(selfUser.clients.count, 1)

        ZMUser.removeUserObserverForToken(token)
    }
    
    func testThatItUpdatesClientObserversWhenClientsAreFaultedAndNewClientIsAdded() {
        
        // given
        var objectID: NSManagedObjectID!
        var syncMOCUser: ZMUser!
        
        syncMOC.performGroupedBlockAndWait {
            syncMOCUser = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            self.syncMOC.saveOrRollback()
            objectID = syncMOCUser.objectID
            XCTAssertEqual(syncMOCUser.clients.count, 0)
        }
        spinMainQueueWithTimeout(0.5)
        
        guard let object = try? uiMOC.existingObjectWithID(objectID), uiMOCUser = object as? ZMUser else {
            return XCTFail("Unable to get user with objectID in uiMOC")
        }
        
        let observer = TestUserObserver()
        let token = ZMUser.addUserObserver(observer, forUsers: [uiMOCUser], managedObjectContext: uiMOC)
        
        // we register for notifications to merge the two contexts
        let notificationCenterToken = NSNotificationCenter.defaultCenter().addObserverForName(
            NSManagedObjectContextDidSaveNotification,
            object: syncMOC,
            queue: .mainQueue()) { note in
                
            self.uiMOC.mergeChangesFromContextDidSaveNotification(note)
            self.uiMOC.saveOrRollback()
        }
        
        // when adding a new client on the syncMOC
        syncMOC.performGroupedBlockAndWait {
            let client = UserClient.insertNewObjectInManagedObjectContext(self.syncMOC)
            syncMOCUser.mutableSetValueForKey(self.UserClientsKey).addObject(client)
            self.syncMOC.saveOrRollback()
            XCTAssertTrue(syncMOCUser.fault)
        }
        
        spinMainQueueWithTimeout(0.5)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then we should receive a changeInfo with clientsChanged on the uiMOC
        let changeInfo = observer.receivedChangeInfo.firstObject as? UserChangeInfo
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        XCTAssertEqual(changeInfo?.clientsChanged, true)
        XCTAssertEqual(uiMOCUser.clients.count, 1)
        
        ZMUser.removeUserObserverForToken(token)
        NSNotificationCenter.defaultCenter().removeObserver(notificationCenterToken)    
    }
    
    func testThatItUpdatesClientObserversWhenClientsAreFaultedAndNewClientIsAddedSameContext() {
        
        // given
        let observer = TestUserObserver()
        let user = ZMUser.insertNewObjectInManagedObjectContext(uiMOC)
        XCTAssertEqual(user.clients.count, 0)
        XCTAssertFalse(user.clients.first?.user?.fault == .Some(true))
        let token = ZMUser.addUserObserver(observer, forUsers: [user], managedObjectContext: user.managedObjectContext)

        uiMOC.saveOrRollback()
        uiMOC.refreshObject(user, mergeChanges: true)
        XCTAssertTrue(user.fault)
        
        // when
        let client = UserClient.insertNewObjectInManagedObjectContext(uiMOC)
        user.mutableSetValueForKey(UserClientsKey).addObject(client)

        uiMOC.saveOrRollback()
        uiMOC.refreshObject(user, mergeChanges: true)
        uiMOC.refreshObject(client, mergeChanges: true)
        
        XCTAssertTrue(user.fault)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        let changeInfo = observer.receivedChangeInfo.firstObject as? UserChangeInfo
        XCTAssertEqual(changeInfo?.clientsChanged, true)
        XCTAssertEqual(user.clients.count, 1)
        
        ZMUser.removeUserObserverForToken(token)
    }

    func testThatItNotifiesTrustChangeForClientsAddedAfterSubscribing() {

        // given
        let observer = TestUserObserver()
        let selfUser = ZMUser.selfUserInContext(uiMOC)
        let selfClient = UserClient.insertNewObjectInManagedObjectContext(uiMOC)
        selfUser.mutableSetValueForKey(UserClientsKey).addObject(selfClient)
        
        let observedUser = ZMUser.insertNewObjectInManagedObjectContext(uiMOC)
        let otherClient = UserClient.insertNewObjectInManagedObjectContext(uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        let token = ZMUser.addUserObserver(observer, forUsers: [observedUser], managedObjectContext: observedUser.managedObjectContext)
        

        // when
        observedUser.mutableSetValueForKey(UserClientsKey).addObject(otherClient)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        //then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        XCTAssertEqual(observer.receivedChangeInfo.firstObject?.clientsChanged, true)
        
        // when
        selfClient.trustClient(otherClient)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(observedUser.clients.count, 1)
        XCTAssertEqual(observer.receivedChangeInfo.count, 2)
        XCTAssertEqual(observer.receivedChangeInfo.map { $0.trustLevelChanged }, [false, true])
        XCTAssertEqual(observer.receivedChangeInfo.map { $0.clientsChanged }, [true, false])
        
        ZMUser.removeUserObserverForToken(token)
    }
    
}

