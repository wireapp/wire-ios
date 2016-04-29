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


@import ZMTesting;
@import ZMUtilities;
@import ZMCDataModel;

#import "MessagingTest.h"
#import "ZMConnection+InvitationToConnect.h"
#import "ZMUserSession+Internal.h"

@interface ZMConnectionTests_InvitationsToConnect : MessagingTest

@end

@implementation ZMConnectionTests_InvitationsToConnect

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatItCreatesANewConnectionToAUserFromAURL
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *userUUID = [NSUUID createUUID];
        NSData *encryptionKey = [ZMConnection invitationToConnectEncryptionKey];
        ZMEncodedNSUUIDWithTimestamp *encodedUUID = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:userUUID timestampDate:[NSDate date] encryptionKey:encryptionKey];
        NSURL *url = [encodedUUID URLWithEncodedUUIDWithTimestampPrefixedWithString:@"wire://connect?code="];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 1u);
        ZMConnection *firstConnection = connections.firstObject;

        XCTAssertEqualObjects(firstConnection.to.remoteIdentifier, userUUID);
        XCTAssertEqual(firstConnection.status, ZMConnectionStatusSent);
    }];
}

- (ZMConnection *)createConnectionToUserWithUUID:(NSUUID *)userUUID initialState:(ZMConnectionStatus)initialState
{
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
    user.remoteIdentifier = userUUID;
    connection.to = user;
    connection.status = initialState;
    return connection;
}

- (NSURL *)createURLWithEncryptedUserUUID:(NSUUID *)userUUID
{
    NSData *encryptionKey = [ZMConnection invitationToConnectEncryptionKey];
    ZMEncodedNSUUIDWithTimestamp *encodedUUID = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:userUUID timestampDate:[NSDate date] encryptionKey:encryptionKey];
    return [encodedUUID URLWithEncodedUUIDWithTimestampPrefixedWithString:@"wire://connect?code="];
}

- (void)testThatItDoesNotCreateANewConnectionToAUserFromAURLIfAnAcceptedConnectionAlreadyExists
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        NSUUID *userUUID = [NSUUID createUUID];
        ZMConnection *initialConnection = [self createConnectionToUserWithUUID:userUUID initialState:ZMConnectionStatusAccepted];
        NSURL *url = [self createURLWithEncryptedUserUUID:userUUID];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 1u);
        XCTAssertEqual(connections.firstObject, initialConnection);
        XCTAssertEqual(initialConnection.status, ZMConnectionStatusAccepted);
    }];
}

- (void)testThatItDoesNotCreateANewConnectionToAUserFromAURLIfASentConnectionAlreadyExists
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        NSUUID *userUUID = [NSUUID createUUID];
        ZMConnection *initialConnection = [self createConnectionToUserWithUUID:userUUID initialState:ZMConnectionStatusSent];
        NSURL *url = [self createURLWithEncryptedUserUUID:userUUID];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 1u);
        XCTAssertEqual(connections.firstObject, initialConnection);
        XCTAssertEqual(initialConnection.status, ZMConnectionStatusSent);
    }];
}

- (void)testThatItAcceptAConnectionToAUserFromAURLIfAPendingConnectionAlreadyExists
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        NSUUID *userUUID = [NSUUID createUUID];
        ZMConnection *initialConnection = [self createConnectionToUserWithUUID:userUUID initialState:ZMConnectionStatusPending];
        NSURL *url = [self createURLWithEncryptedUserUUID:userUUID];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 1u);
        XCTAssertEqual(connections.firstObject, initialConnection);
        XCTAssertEqual(initialConnection.status, ZMConnectionStatusAccepted);
        XCTAssertTrue([initialConnection.keysThatHaveLocalModifications containsObject:ZMConnectionStatusKey]);
    }];
}

- (void)testThatItDoesNotAcceptAConnectionToAUserFromAURLIfABlockedConnectionAlreadyExists
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        NSUUID *userUUID = [NSUUID createUUID];
        ZMConnection *initialConnection = [self createConnectionToUserWithUUID:userUUID initialState:ZMConnectionStatusBlocked];
        NSURL *url = [self createURLWithEncryptedUserUUID:userUUID];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 1u);
        XCTAssertEqual(connections.firstObject, initialConnection);
        XCTAssertEqual(initialConnection.status, ZMConnectionStatusBlocked);
        XCTAssertFalse([initialConnection.keysThatHaveLocalModifications containsObject:ZMConnectionStatusKey]);
    }];
}

- (void)testThatItAcceptAConnectionToAUserFromAURLIfAnIgnoredConnectionAlreadyExists
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        NSUUID *userUUID = [NSUUID createUUID];
        ZMConnection *initialConnection = [self createConnectionToUserWithUUID:userUUID initialState:ZMConnectionStatusIgnored];
        NSURL *url = [self createURLWithEncryptedUserUUID:userUUID];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 1u);
        XCTAssertEqual(connections.firstObject, initialConnection);
        XCTAssertEqual(initialConnection.status, ZMConnectionStatusAccepted);
        XCTAssertTrue([initialConnection.keysThatHaveLocalModifications containsObject:ZMConnectionStatusKey]);
    }];
}

- (void)testThatItStoresInvitationsToConnectFromURLAndItProcessesThem
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        NSUUID *userID1 = [NSUUID createUUID];
        NSUUID *userID2 = [NSUUID createUUID];

        NSURL *url1 = [self createURLWithEncryptedUserUUID:userID1];
        NSURL *url2 = [self createURLWithEncryptedUserUUID:userID2];

        // when
        [ZMConnection storeInvitationToConnectFromURL:url1 managedObjectContext:self.syncMOC];
        [ZMConnection storeInvitationToConnectFromURL:url2 managedObjectContext:self.syncMOC];

        // and expect
        id mockConnection = [OCMockObject mockForClass:ZMConnection.class];
        [[mockConnection expect] sendInvitationToConnectFromURL:url1 managedObjectContext:self.syncMOC];
        [[mockConnection expect] sendInvitationToConnectFromURL:url2 managedObjectContext:self.syncMOC];

        // when
        [ZMConnection processStoredInvitationsToConnectFromURLInManagedObjectContext:self.syncMOC];

        // then
        [mockConnection stopMocking];
        [mockConnection verify];

    }];
}


- (void)testThatItProcessesStoredInvitationsToConnectOnlyOnce
{
    [self.syncMOC performGroupedBlockAndWait:^{

        // given
        NSUUID *userID1 = [NSUUID createUUID];
        NSUUID *userID2 = [NSUUID createUUID];

        NSURL *url1 = [self createURLWithEncryptedUserUUID:userID1];
        NSURL *url2 = [self createURLWithEncryptedUserUUID:userID2];

        // expect
        id mockConnection = [OCMockObject mockForClass:ZMConnection.class];
        [[mockConnection expect] sendInvitationToConnectFromURL:url1 managedObjectContext:self.syncMOC];

        // when
        [ZMConnection storeInvitationToConnectFromURL:url1 managedObjectContext:self.syncMOC];
        [ZMConnection processStoredInvitationsToConnectFromURLInManagedObjectContext:self.syncMOC];

        // then
        [mockConnection verify];

        // and expect
        [[mockConnection reject] sendInvitationToConnectFromURL:url1 managedObjectContext:OCMOCK_ANY];
        [[mockConnection expect] sendInvitationToConnectFromURL:url2 managedObjectContext:self.syncMOC];

        // when
        [ZMConnection storeInvitationToConnectFromURL:url2 managedObjectContext:self.syncMOC];
        [ZMConnection processStoredInvitationsToConnectFromURLInManagedObjectContext:self.syncMOC];

        // then
        [mockConnection verify];


        // and expect
        [[mockConnection reject] sendInvitationToConnectFromURL:OCMOCK_ANY managedObjectContext:OCMOCK_ANY];

        // when
        [ZMConnection processStoredInvitationsToConnectFromURLInManagedObjectContext:self.syncMOC];

        // then
        [mockConnection stopMocking];
        [mockConnection verify];

    }];
}

- (void)testThatItSendsARequestToOpenTheConversationWhenSendingAnInvitationToConnect
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *userUUID = [NSUUID createUUID];
        NSData *encryptionKey = [ZMConnection invitationToConnectEncryptionKey];
        ZMEncodedNSUUIDWithTimestamp *encodedUUID = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:userUUID timestampDate:[NSDate date] encryptionKey:encryptionKey];
        NSURL *url = [encodedUUID URLWithEncodedUUIDWithTimestampPrefixedWithString:@"wire://connect?code="];
        __block ZMConversation *requestedConversation;

        // expect
        id mockUserSession = [OCMockObject mockForClass:ZMUserSession.class];
        [[[mockUserSession expect] classMethod] requestToOpenSyncConversationOnUI:ZM_ARG_SAVE(requestedConversation)];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        [mockUserSession verify];
        [mockUserSession stopMocking];
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 1u);
        ZMConnection *firstConnection = connections.firstObject;
        XCTAssertEqual(firstConnection.conversation, requestedConversation);
    }];

}

- (void)testThatItDoesNotCreateANewConnectionToAUserFromAURLIfTheURLIsForTheSelfUser
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given

        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];

        NSData *encryptionKey = [ZMConnection invitationToConnectEncryptionKey];
        ZMEncodedNSUUIDWithTimestamp *encodedUUID = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:selfUser.remoteIdentifier timestampDate:[NSDate date] encryptionKey:encryptionKey];
        NSURL *url = [encodedUUID URLWithEncodedUUIDWithTimestampPrefixedWithString:@"wire://connect?code="];

        // when
        [ZMConnection sendInvitationToConnectFromURL:url managedObjectContext:self.syncMOC];

        // then
        NSArray *connections = [ZMConnection connectionsInMangedObjectContext:self.syncMOC];
        XCTAssertEqual(connections.count, 0u);
    }];
}


@end
