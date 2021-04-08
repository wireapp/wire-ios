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


@import Foundation;
@import WireDataModel;

#import "ZMBaseManagedObjectTest.h"

@interface ZMSearchUserTests : ZMBaseManagedObjectTest <ZMUserObserver, ZMManagedObjectContextProvider>
@property (nonatomic) NSMutableArray *userNotifications;
@end

@implementation ZMSearchUserTests

- (NSManagedObjectContext *)syncManagedObjectContext
{
    return self.syncMOC;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.uiMOC;
}

- (void)setUp {
    [super setUp];

    self.userNotifications = [NSMutableArray array];
}

- (void)tearDown {
    self.userNotifications = nil;
    [super tearDown];
}

- (void)userDidChange:(UserChangeInfo *)note
{
    [self.userNotifications addObject:note];
}

- (void)testThatItComparesEqualBasedOnRemoteID;
{
    // given
    NSUUID *remoteIDA = [NSUUID createUUID];
    NSUUID *remoteIDB = [NSUUID createUUID];
    
    
    
    ZMSearchUser *user1 = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                   name:@"A"
                                                                 handle:@"a"
                                                            accentColor:ZMAccentColorStrongLimeGreen
                                                       remoteIdentifier:remoteIDA
                                                                 domain:nil
                                                         teamIdentifier:nil
                                                                   user:nil
                                                                contact:nil];
    
    
    // (1)
    ZMSearchUser *user2 = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                   name:@"B"
                                                                 handle:@"b"
                                                            accentColor:ZMAccentColorSoftPink
                                                       remoteIdentifier:remoteIDA
                                                                 domain:nil
                                                         teamIdentifier:nil
                                                                   user:nil
                                                                contact:nil];
    
    XCTAssertEqualObjects(user1, user2);
    XCTAssertEqual(user1.hash, user2.hash);
    
    // (2)
    ZMSearchUser *user3 = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                   name:@"A"
                                                                 handle:@"b"
                                                            accentColor:ZMAccentColorStrongLimeGreen
                                                       remoteIdentifier:remoteIDB
                                                                 domain:nil
                                                         teamIdentifier:nil
                                                                   user:nil
                                                                contact:nil];
    
    XCTAssertNotEqualObjects(user1, user3);
}

- (void)testThatItComparesEqualBasedOnContactWhenRemoteIDIsNil
{
    // Given
    ZMAddressBookContact *contact1 = [[ZMAddressBookContact alloc] init];
    contact1.firstName = @"A";
    
    ZMAddressBookContact *contact2  =[[ZMAddressBookContact alloc] init];
    contact2.firstName = @"B";
    
    OCMockObject *userSession = [OCMockObject niceMockForProtocol:@protocol(ZMManagedObjectContextProvider)];
    [[[userSession stub] andReturn:self.syncMOC] syncManagedObjectContext];
    
    
    
    ZMSearchUser *user1 = [[ZMSearchUser alloc] initWithContextProvider:self contact:contact1 user:nil];
    ZMSearchUser *user2 = [[ZMSearchUser alloc] initWithContextProvider:self contact:contact1 user:nil];
    ZMSearchUser *user3 = [[ZMSearchUser alloc] initWithContextProvider:self contact:contact2 user:nil];
    
    // Then
    XCTAssertEqualObjects(user1, user2);
    XCTAssertNotEqualObjects(user1, user3);
}

- (void)testThatItHasAllDataItWasInitializedWith
{
    // given
    NSString *name = @"John Doe";
    NSString *handle = @"doe";
    NSUUID *remoteID = [NSUUID createUUID];
    
    // when
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:name
                                                                      handle:handle
                                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                            remoteIdentifier:remoteID
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:nil
                                                                     contact:nil];

    
    // then
    XCTAssertEqualObjects(searchUser.name, @"John Doe");
    XCTAssertEqual(searchUser.accentColorValue, ZMAccentColorStrongLimeGreen);
    XCTAssertEqual(searchUser.isConnected, NO);
    XCTAssertNil(searchUser.completeImageData);
    XCTAssertNil(searchUser.previewImageData);
    XCTAssertNil(searchUser.user);
    XCTAssertEqualObjects(searchUser.handle, handle);
}


- (void)testThatItUsesDataFromAUserIfItHasOne
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Actual name";
    user.handle = @"my_handle";
    user.accentColorValue = ZMAccentColorVividRed;
    user.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    user.connection.status = ZMConnectionStatusAccepted;
    user.remoteIdentifier = [NSUUID createUUID];
    [user setImageData:[@"image medium data" dataUsingEncoding:NSUTF8StringEncoding] size:ProfileImageSizeComplete];
    [user setImageData:[@"image small profile data" dataUsingEncoding:NSUTF8StringEncoding] size:ProfileImageSizePreview];
    [self.uiMOC saveOrRollback];
    
   
    
    // when
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@"Wrong name"
                                                                      handle:@"not_my_handle"
                                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                            remoteIdentifier:[NSUUID createUUID]
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:user
                                                                     contact:nil];

    // then
    XCTAssertEqualObjects(searchUser.name, user.name);
    XCTAssertEqualObjects(searchUser.handle, user.handle);
    XCTAssertEqualObjects(searchUser.name, user.name);
    XCTAssertEqual(searchUser.accentColorValue, user.accentColorValue);
    XCTAssertEqual(searchUser.isConnected, user.isConnected);
    XCTAssertEqualObjects(searchUser.completeImageData, user.completeImageData);
    XCTAssertEqualObjects(searchUser.previewImageData, user.previewImageData);
    XCTAssertEqual(searchUser.user, user);
}

@end


@implementation ZMSearchUserTests (Connections)

- (void)testThatItCreatesAConnectionForASeachUserThatHasNoLocalUser;
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@"Hans"
                                                                      handle:@"hans"
                                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                            remoteIdentifier:NSUUID.createUUID
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:nil
                                                                     contact:nil];
    
    // when
    [searchUser connectWithMessage:@"Hey!"];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSArray *connections = [self.uiMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]];
    XCTAssertEqual(connections.count, 1u);
    ZMConnection *connection = connections[0];
    ZMUser *user = connection.to;
    XCTAssertNotNil(user);
    XCTAssertEqualObjects(user.name, @"Hans");
    XCTAssertEqual(user.accentColorValue, ZMAccentColorStrongLimeGreen);
    XCTAssertNotNil(connection.conversation);
    XCTAssertEqual(connection.status, ZMConnectionStatusSent);
    XCTAssertEqualObjects(connection.message, @"Hey!");
}

- (void)testThatItDoesNotConnectIfTheSearchUserHasNoRemoteIdentifier;
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@"Hans"
                                                                      handle:@"hans"
                                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                            remoteIdentifier:nil
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:nil
                                                                     contact:nil];
    
    // when
    [searchUser connectWithMessage:@"Hey!"];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse(self.uiMOC.hasChanges);
    XCTAssertEqual([self.uiMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 0u);
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertFalse(self.syncMOC.hasChanges);
        XCTAssertEqual([self.syncMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 0u);
    }];
}


- (void)testThatItStoresTheConnectionRequestMessage;
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@"Hans"
                                                                      handle:@"hans"
                                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                            remoteIdentifier:NSUUID.createUUID
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:nil
                                                                     contact:nil];
    NSString *connectionMessage = @"very unique connection message";
    
    // when
    [searchUser connectWithMessage:connectionMessage];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(searchUser.connectionRequestMessage, connectionMessage);
}


- (void)testThatItCanBeConnectedIfItIsNotAlreadyConnected
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@"Hans"
                                                                      handle:@"hans"
                                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                            remoteIdentifier:NSUUID.createUUID
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:nil
                                                                     contact:nil];

    
    // then
    XCTAssertTrue(searchUser.canBeConnected);
}


- (void)testThatItCanNotBeConnectedIfItHasNoRemoteIdentifier
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@"Hans"
                                                                      handle:@"hans"
                                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                            remoteIdentifier:nil
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:nil
                                                                     contact:nil];
    
    // then
    XCTAssertFalse(searchUser.canBeConnected);
}

- (void)testThatItConnectsIfTheSearchUserHasANonConnectedUser;
{
    // We expect the search user to only have a user, if that user has a (matching)
    // remote identifier. Hence this should have no effect even if the user does
    // in fact not have a remote identifier.
    
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);

    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@""
                                                                      handle:@""
                                                                 accentColor:ZMAccentColorUndefined
                                                            remoteIdentifier:nil
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:user
                                                                     contact:nil];
    
    [searchUser connectWithMessage:@"Hey!"];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertFalse(self.uiMOC.hasChanges);
    XCTAssertEqual([self.uiMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 1u);
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertFalse(self.syncMOC.hasChanges);
        XCTAssertEqual([self.syncMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 1u);
    }];
    XCTAssertEqual(user.connection.status, ZMConnectionStatusSent);
}

- (void)testThatItDoesNotConnectIfTheSearchUserHasAConnectedUser;
{
    // We expect the search user to only have a user, if that user has a (matching)
    // remote identifier. Hence this should have no effect even if the user does
    // in fact not have a remote identifier.
    
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Hans";
    user.handle = @"hans";
    user.connection.status = ZMConnectionStatusAccepted;
    XCTAssert([self.uiMOC saveOrRollback]);

    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithContextProvider:self
                                                                        name:@"Hans"
                                                                      handle:@"hans"
                                                                 accentColor:ZMAccentColorUndefined
                                                            remoteIdentifier:[NSUUID createUUID]
                                                                      domain:nil
                                                              teamIdentifier:nil
                                                                        user:user
                                                                     contact:nil];
    
    [searchUser connectWithMessage:@"Hey!"];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse(self.uiMOC.hasChanges);
    XCTAssertEqual([self.uiMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 1u);
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertFalse(self.syncMOC.hasChanges);
        XCTAssertEqual([self.syncMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 1u);
    }];
}

@end
