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


import XCTest
@testable import ZMCDataModel

class UserClientObserverTokenTests: ZMBaseManagedObjectTest {

    class TestUserClientObserver : NSObject, UserClientObserver {

        var receivedChangeInfo : [UserClientChangeInfo] = []

        func userClientDidChange(_ changes: UserClientChangeInfo) {
            receivedChangeInfo.append(changes)
        }
    }
    
    override func setUp() {
        super.setUp()
        self.uiMOC.globalManagedObjectContextObserver.syncCompleted(Notification(name: Notification.Name(rawValue: "fake"), object: nil))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    let userInfoKeys = [
        UserClientChangeInfoKey.TrustedByClientsChanged,
        UserClientChangeInfoKey.IgnoredByClientsChanged
        ].map { $0.rawValue }

    func checkThatItNotifiesTheObserverOfAChange(_ userClient : UserClient, modifier: (UserClient) -> Void, expectedChangedFields: [String], customAffectedKeys: AffectedKeys? = nil) {

        // given
        self.uiMOC.saveOrRollback()

        let observer = TestUserClientObserver()
        print(">>>>>> \(observer)")
        let token = userClient.addObserver(observer)
        defer { (token as? UserClientObserverToken)?.tearDown() }


        // when
        modifier(userClient)
        self.uiMOC.saveOrRollback()

        // then
        let changeCount = observer.receivedChangeInfo.count
        XCTAssertEqual(changeCount, 1)

        // and when
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, changeCount, "Should not have changed further once")
        print(">>>>>> \(observer)")

        guard let changes = observer.receivedChangeInfo.first else { return }
        for key in userInfoKeys {
            guard !expectedChangedFields.contains(key) else { continue }
            guard let value = changes.value(forKey: key) as? NSNumber else { return XCTFail("Can't find key or key is not boolean for '\(key)'") }
            XCTAssertFalse(value.boolValue, "\(key) was supposed to be false")
        }
        
        UserClient.removeObserverForUserClientToken(token as! UserClientObserverToken)
        
    }

    func testThatItNotifiesTheObserverOfTrustedByClientsChange() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(client,
            modifier: { otherClient.trustClient($0) },
            expectedChangedFields: [UserClientChangeInfoKey.TrustedByClientsChanged.rawValue]
        )

        XCTAssertTrue(client.trustedByClients.contains(otherClient))
    }

    func testThatItNotifiesTheObserverOfIgnoredByClientsChange() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        otherClient.trustClient(client)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(client,
            modifier: { otherClient.ignoreClient($0) },
            expectedChangedFields: [
                UserClientChangeInfoKey.IgnoredByClientsChanged.rawValue,
                UserClientChangeInfoKey.TrustedByClientsChanged.rawValue
            ]
        )

        XCTAssertTrue(client.ignoredByClients.contains(otherClient))
    }
    
    func testThatItNotifiesTheObserverOfFingerprintChange() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.fingerprint = String.createAlphanumerical().data(using: String.Encoding.utf8)
        self.uiMOC.saveOrRollback()
        
        let newFingerprint = String.createAlphanumerical().data(using: String.Encoding.utf8)
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(client,
            modifier: { _ in client.fingerprint = newFingerprint },
            expectedChangedFields: [UserClientChangeInfoKey.FingerprintChanged.rawValue]
        )
        
        XCTAssertTrue(client.fingerprint == newFingerprint)
    }

    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        // given
        let client = UserClient.insertNewObject(in: self.uiMOC)
        let otherClient = UserClient.insertNewObject(in: self.uiMOC)
        otherClient.trustClient(client)
        self.uiMOC.saveOrRollback()

        let observer = TestUserClientObserver()
        let token = UserClientObserverToken(observer: observer, managedObjectContext: client.managedObjectContext!, userClient: client)
        token.tearDown()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(client,
            modifier: { otherClient.ignoreClient($0) },
            expectedChangedFields: [
                UserClientChangeInfoKey.TrustedByClientsChanged.rawValue,
                UserClientChangeInfoKey.IgnoredByClientsChanged.rawValue
            ]
        )

        XCTAssertEqual(observer.receivedChangeInfo.count, 0)
    }

}
