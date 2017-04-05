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

@interface ZMSearchUserTests : ZMBaseManagedObjectTest <ZMUserObserver>
@property (nonatomic) NSMutableArray *userNotifications;
@end

@implementation ZMSearchUserTests

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
    ZMSearchUser *user1 = [[ZMSearchUser alloc] initWithName:@"A"
                                                      handle:@"a"
                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                    remoteID:remoteIDA
                                                        user:nil
                                    syncManagedObjectContext:self.syncMOC
                                      uiManagedObjectContext:self.uiMOC];


    // (1)
    ZMSearchUser *user2 = [[ZMSearchUser alloc] initWithName:@"B"
                                                      handle:@"b"
                                                 accentColor:ZMAccentColorSoftPink
                                                    remoteID:remoteIDA
                                                        user:nil
                                    syncManagedObjectContext: self.syncMOC
                                      uiManagedObjectContext:self.uiMOC];

    XCTAssertEqualObjects(user1, user2);
    XCTAssertEqual(user1.hash, user2.hash);
    
    // (2)
    ZMSearchUser *user3 = [[ZMSearchUser alloc] initWithName:@"A"
                                                      handle:@"b"
                                                 accentColor:ZMAccentColorStrongLimeGreen
                                                    remoteID:remoteIDB
                                                        user:nil
                                    syncManagedObjectContext:self.syncMOC
                                      uiManagedObjectContext:self.uiMOC];

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
    
    ZMSearchUser *user1 = [[ZMSearchUser alloc] initWithContact:contact1 user:nil userSession:(id<ZMManagedObjectContextProvider>)userSession];
    ZMSearchUser *user2 = [[ZMSearchUser alloc] initWithContact:contact1 user:nil userSession:(id<ZMManagedObjectContextProvider>)userSession];
    ZMSearchUser *user3 = [[ZMSearchUser alloc] initWithContact:contact2 user:nil userSession:(id<ZMManagedObjectContextProvider>)userSession];
    
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
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:name
                                                           handle:handle
                                                      accentColor:ZMAccentColorStrongLimeGreen
                                                         remoteID:remoteID
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    // then
    XCTAssertEqualObjects(searchUser.displayName, name);
    XCTAssertEqualObjects(searchUser.remoteIdentifier, remoteID);
    XCTAssertEqual(searchUser.accentColorValue, ZMAccentColorStrongLimeGreen);
    XCTAssertEqual(searchUser.isConnected, NO);
    XCTAssertNil(searchUser.imageMediumData);
    XCTAssertNil(searchUser.imageSmallProfileData);
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
    user.imageMediumData = [@"image medium data" dataUsingEncoding:NSUTF8StringEncoding];
    user.imageSmallProfileData = [@"image small profile data" dataUsingEncoding:NSUTF8StringEncoding];
    [self.uiMOC saveOrRollback];
    
    // when
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"Wrong name"
                                                           handle:@"not_my_handle"
                                                      accentColor:ZMAccentColorStrongLimeGreen
                                                         remoteID:[NSUUID createUUID]
                                                             user:user
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    // then
    XCTAssertEqualObjects(searchUser.name, user.name);
    XCTAssertEqualObjects(searchUser.handle, user.handle);
    XCTAssertEqualObjects(searchUser.displayName, user.displayName);
    XCTAssertEqual(searchUser.accentColorValue, user.accentColorValue);
    XCTAssertEqual(searchUser.isConnected, user.isConnected);
    XCTAssertEqualObjects(searchUser.remoteIdentifier, user.remoteIdentifier);
    XCTAssertEqualObjects(searchUser.imageMediumData, user.imageMediumData);
    XCTAssertEqualObjects(searchUser.imageSmallProfileData, user.imageSmallProfileData);
    XCTAssertEqual(searchUser.user, user);
}

- (void)testThatItCreatesSearchUserWhenInitialisedWithUser
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *remoteIdentifierString1 = [NSUUID createUUID].UUIDString;
    user1.remoteIdentifier = remoteIdentifierString1.UUID;
    
    ZMUser *commonUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *remoteIdentifierString2 = [NSUUID createUUID].UUIDString;
    commonUser.remoteIdentifier = remoteIdentifierString2.UUID;
    
    OCMockObject *userSession = [OCMockObject niceMockForProtocol:@protocol(ZMManagedObjectContextProvider)];
    [[[userSession stub] andReturn:self.uiMOC] managedObjectContext];
    
    OCMockObject *userClassMock = [OCMockObject niceMockForClass:ZMUser.class];
    [[[userClassMock stub] andReturn:[[NSOrderedSet alloc] initWithObject:user1]] usersWithRemoteIDs:OCMOCK_ANY inContext:OCMOCK_ANY];
    [self.uiMOC saveOrRollback];
    
    // when
    ZMSearchUser *searchUser = [ZMSearchUser usersWithUsers:@[user1] userSession:(id<ZMManagedObjectContextProvider>)userSession].firstObject;

    // then
    XCTAssertEqualObjects(searchUser.user, user1);
}

@end


@implementation ZMSearchUserTests (Connections)

- (void)testThatItCreatesAConnectionForASeachUserThatHasNoLocalUser;
{
    // given
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"Hans"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorStrongLimeGreen
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    OCMockObject *userSession = [OCMockObject niceMockForProtocol:@protocol(ZMManagedObjectContextProvider)];
    [[[userSession stub] andReturn:self.syncMOC] syncManagedObjectContext];
    [[[userSession stub] andReturn:self.uiMOC] managedObjectContext];
    searchUser.remoteIdentifier = [NSUUID createUUID];
    XCTAssertFalse(searchUser.isPendingApprovalByOtherUser);
    
    // expect
    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"Callback called"];
    [searchUser connectWithMessageText:@"Hey!" completionHandler:^{
        [callbackCalled fulfill];
        NSArray *connections = [self.uiMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]];
        XCTAssertEqual(connections.count, 1u);
        ZMConnection *connection = connections[0];
        ZMUser *user = connection.to;
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(user.name, @"Hans");
        XCTAssertEqual(user.accentColorValue, ZMAccentColorStrongLimeGreen);
        __block NSUUID *searchContextRemoteID = nil;
        [self.syncMOC performGroupedBlockAndWait:^{
            searchContextRemoteID = searchUser.remoteIdentifier;
            XCTAssertTrue(searchUser.isPendingApprovalByOtherUser);
        }];
        XCTAssertEqualObjects(user.remoteIdentifier, searchContextRemoteID);
        XCTAssertNotNil(connection.conversation);
        XCTAssertEqual(connection.status, ZMConnectionStatusSent);
        XCTAssertEqualObjects(connection.message, @"Hey!");
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItDoesNotConnectIfTheSearchUserHasNoRemoteIdentifier;
{
    // given
    
    ZMSearchUser *user = [[ZMSearchUser alloc] initWithName:@"Hans"
                                                     handle:@"hans"
                                                accentColor:ZMAccentColorStrongLimeGreen
                                                   remoteID:[NSUUID createUUID]
                                                       user:nil
                                   syncManagedObjectContext:self.syncMOC
                                     uiManagedObjectContext:self.uiMOC];

    user.remoteIdentifier = nil;
    
    // expect
    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"Callback called"];
    [user connectWithMessageText:@"Hey!" completionHandler:^{
        [callbackCalled fulfill];
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
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
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"Hans"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorStrongLimeGreen
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    searchUser.remoteIdentifier = [NSUUID createUUID];
    
    OCMockObject *userSession = [OCMockObject niceMockForProtocol:@protocol(ZMManagedObjectContextProvider)];
    [[[userSession stub] andReturn:self.syncMOC] syncManagedObjectContext];
    [[[userSession stub] andReturn:self.uiMOC] managedObjectContext];
    
    NSString *connectionMessage = @"very unique connection message";
    
    // expect
    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"Callback called"];
    [searchUser connectWithMessageText:connectionMessage completionHandler:^{
        [callbackCalled fulfill];
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    XCTAssertEqualObjects(searchUser.connectionRequestMessage, connectionMessage);
}


- (void)testThatItCanBeConnectedIfItIsNotAlreadyConnected
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"Hans"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorStrongLimeGreen
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    // then
    XCTAssertTrue(searchUser.canBeConnected);
}


- (void)testThatItCanNotBeConnectedIfItHasNoRemoteIdentifier
{
    // given
    __block ZMSearchUser *searchUser;
    
    [self performIgnoringZMLogError:^{
        searchUser = [[ZMSearchUser alloc] initWithName:@"Hans"
                                                 handle:@"hans"
                                            accentColor:ZMAccentColorStrongLimeGreen
                                               remoteID:nil
                                                   user:nil
                               syncManagedObjectContext:self.syncMOC
                                 uiManagedObjectContext:self.uiMOC];

    }];
    
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
    
    __block ZMSearchUser *searchUser;
    [self performIgnoringZMLogError:^{
        searchUser = [[ZMSearchUser alloc] initWithName:nil
                                                 handle:nil
                                            accentColor:ZMAccentColorUndefined
                                               remoteID:nil
                                                   user:user
                               syncManagedObjectContext:self.syncMOC
                                 uiManagedObjectContext:self.uiMOC];

    }];
    searchUser.remoteIdentifier = nil;
    
    // expect
    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"Callback called"];
    [searchUser connectWithMessageText:@"Hey!" completionHandler:^{
        [callbackCalled fulfill];
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
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

- (void)testThatALocalUserIsUpdatedWhenTheSearchUserHasAnUpdatedNameAndHandle
{
    // Given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Bruno";
    user.handle = @"bruno";
    XCTAssert([self.uiMOC saveOrRollback]);

    // When
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"Hans"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorUndefined
                                                         remoteID:nil
                                                             user:user
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NOT_USED(searchUser);

    // Then
    XCTAssertEqualObjects(user.name, @"Hans");
    XCTAssertEqualObjects(user.handle, @"hans");
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

    __block ZMSearchUser *searchUser;
    [self performIgnoringZMLogError:^{
        searchUser = [[ZMSearchUser alloc] initWithName:@"Hans"
                                                 handle:@"hans"
                                            accentColor:ZMAccentColorStrongLimeGreen
                                               remoteID:[NSUUID createUUID]
                                                   user:user
                               syncManagedObjectContext:self.syncMOC
                                 uiManagedObjectContext:self.uiMOC];

    }];
    searchUser.remoteIdentifier = nil;
    
    // expect
    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"Callback called"];
    [searchUser connectWithMessageText:@"Hey!" completionHandler:^{
        [callbackCalled fulfill];
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    XCTAssertFalse(self.uiMOC.hasChanges);
    XCTAssertEqual([self.uiMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 1u);
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertFalse(self.syncMOC.hasChanges);
        XCTAssertEqual([self.syncMOC executeFetchRequestOrAssert:[ZMConnection sortedFetchRequest]].count, 1u);
    }];
}

@end



@implementation ZMSearchUserTests (SearchUserProfileImage)

- (void)testThatItReturnsSmallProfileImageFromCacheIfItHasNoUser
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    // when
    NSData *image = searchUser.imageSmallProfileData;
    
    // then
    XCTAssertEqual(mockImage, image);
}

- (void)testThatItReturnsSmallProfileImageFromUserIfItHasAUser
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *mockImage2 = [@"bar2" dataUsingEncoding:NSUTF8StringEncoding];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    user.smallProfileRemoteIdentifier = [NSUUID createUUID];
    user.imageSmallProfileData = mockImage;
    
    [self.uiMOC saveOrRollback];
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:user.remoteIdentifier
                                                             user:user
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [cache setObject:mockImage2 forKey:searchUser.remoteIdentifier];
    
    // when
    NSData *image = searchUser.imageSmallProfileData;
    
    // then
    XCTAssertEqualObjects(mockImage, image);
}

- (void)testThatItReturnsRemoteIdentifierAsTheSmallProfileImageIdentifierIfItHasACachedImage
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    // when
    NSString *identifier = searchUser.imageSmallProfileIdentifier;
    
    // then
    XCTAssertEqualObjects(identifier, searchUser.remoteIdentifier.transportString);
}

- (void)testThatItReturnsANulRemoteIdentifierAsTheSmallProfileImageIdentifierIfItHasNoCachedImage
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    // when
    NSString *identifier = searchUser.imageSmallProfileIdentifier;
    
    // then
    XCTAssertNil(identifier);
}

- (void)testThatItReturnsSmallProfileImageIdentifierFromUserIfItHasAUser
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];

    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    user.imageSmallProfileData = mockImage;
    user.localSmallProfileRemoteIdentifier = [NSUUID createUUID];
    
    [self.uiMOC saveOrRollback];
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:user.remoteIdentifier
                                                             user:user
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    // when
    NSString *imageIdentifier = searchUser.imageSmallProfileIdentifier;
    
    // then
    NSString *fetchedIdentifier = user.imageSmallProfileIdentifier;
    XCTAssertEqualObjects(imageIdentifier, fetchedIdentifier);
}

- (void)testThatItStoresTheCachedSmallProfileData;
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    NSData *dataA = [searchUser imageSmallProfileData];
    XCTAssertNotNil(dataA);
    NSString *dataIdentifierA = [searchUser imageSmallProfileIdentifier];
    XCTAssertNotNil(dataIdentifierA);
    
    // when
    [cache removeObjectForKey:searchUser.remoteIdentifier];
    NSData *dataB = [searchUser imageSmallProfileData];
    NSString *dataIdentifierB = [searchUser imageSmallProfileIdentifier];
    
    // then
    AssertEqualData(dataA, dataB);
    XCTAssertEqualObjects(dataIdentifierA, dataIdentifierB);
}

- (void)testThat_isLocalOrHasCachedProfileImageData_returnsNo
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    // then
    XCTAssertFalse(searchUser.isLocalOrHasCachedProfileImageData);
}

- (void)testThat_isLocalOrHasCachedProfileImageData_returnsYesForLocalUser
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    [self.uiMOC saveOrRollback];
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:nil
                                                           handle:nil
                                                      accentColor:ZMAccentColorUndefined
                                                         remoteID:nil
                                                             user:user
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    // then
    XCTAssertTrue(searchUser.isLocalOrHasCachedProfileImageData);
}

- (void)testThat_isLocalOrHasCachedProfileImageData_returnsYesForAUserWithCachedData
{
    // given
    NSData *smallImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *mediumImage = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];

    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *smallCache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [smallCache setObject:smallImage forKey:searchUser.remoteIdentifier];
    
    NSCache *mediumCache = [ZMSearchUser searchUserToMediumImageCache];
    [mediumCache setObject:mediumImage forKey:searchUser.remoteIdentifier];
    
    // then
    XCTAssertTrue(searchUser.isLocalOrHasCachedProfileImageData);
}

- (void)testThat_isLocalOrHasCachedProfileImageData_returnsYesForAUserWithCachedSmallData_MediumLegcayId
{
    // given
    NSData *smallImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    NSUUID *mediumLegacyId = [NSUUID UUID];
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];
    
    NSCache *smallImageCache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [smallImageCache setObject:smallImage forKey:searchUser.remoteIdentifier];
    
    NSCache *mediumAssetCache = [ZMSearchUser searchUserToMediumAssetIDCache];
    [mediumAssetCache setObject:[[SearchUserAssetObjC alloc] initWithLegacyId:mediumLegacyId] forKey:searchUser.remoteIdentifier];
    
    // then
    XCTAssertTrue(searchUser.isLocalOrHasCachedProfileImageData);
}

- (void)testThat_isLocalOrHasCachedProfileImageData_returnsYesForAUserWithCachedSmallData_MediumAssetKey
{
    // given
    NSData *smallImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *assetKey = @"asset-key";

    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *smallImageCache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [smallImageCache setObject:smallImage forKey:searchUser.remoteIdentifier];

    NSCache *mediumAssetCache = [ZMSearchUser searchUserToMediumAssetIDCache];
    [mediumAssetCache setObject:[[SearchUserAssetObjC alloc] initWithAssetKey:assetKey] forKey:searchUser.remoteIdentifier];

    // then
    XCTAssertTrue(searchUser.isLocalOrHasCachedProfileImageData);
}

- (void)testThat_isLocalOrHasCachedProfileImageData_returnsNoIfMediumAssetIDAndDataAreNotSet
{
    // given
    NSData *smallImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];
    
    NSCache *smallImageCache = [ZMSearchUser searchUserToSmallProfileImageCache];
    [smallImageCache setObject:smallImage forKey:searchUser.remoteIdentifier];
    
    // then
    XCTAssertFalse(searchUser.isLocalOrHasCachedProfileImageData);
}

@end



@implementation ZMSearchUserTests (MediumImage)

- (void)testThatItReturnsMediumLegacyIdFromCacheIfItHasNoMediumAssetID
{
    // given
    NSUUID *legacyId = [NSUUID UUID];
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];
    
    NSCache *cache = [ZMSearchUser searchUserToMediumAssetIDCache];
    [cache setObject:[[SearchUserAssetObjC alloc] initWithLegacyId:legacyId] forKey:searchUser.remoteIdentifier];
    
    // when
    NSUUID *mediumAssetID = searchUser.mediumLegacyId;
    
    // then
    XCTAssertEqualObjects(mediumAssetID, legacyId);
}

- (void)testThatItReturnsCompleteAssetKeyFromCacheIfItHasNoMediumAssetID
{
    // given
    NSString *completeAssetKey = @"asset-key";

    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToMediumAssetIDCache];
    [cache setObject:[[SearchUserAssetObjC alloc] initWithAssetKey:completeAssetKey] forKey:searchUser.remoteIdentifier];

    // when
    NSString *expectedKey = searchUser.completeAssetKey;

    // then
    XCTAssertEqualObjects(expectedKey, completeAssetKey);
}

- (void)testThatItReturnsMediumImageFromCacheIfItHasNoUser
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToMediumImageCache];
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    // when
    NSData *image = searchUser.imageMediumData;
    
    // then
    XCTAssertEqual(mockImage, image);
}

- (void)testThatItReturnsMediumImageFromUserIfItHasAUser
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *mockImage2 = [@"bar2" dataUsingEncoding:NSUTF8StringEncoding];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    user.mediumRemoteIdentifier = [NSUUID createUUID];
    user.imageMediumData = mockImage;
    
    [self.uiMOC saveOrRollback];
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:user.remoteIdentifier
                                                             user:user
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToMediumImageCache];
    [cache setObject:mockImage2 forKey:searchUser.remoteIdentifier];
    
    // when
    NSData *image = searchUser.imageMediumData;
    
    
    // then
    XCTAssertEqualObjects(mockImage, image);
}

- (void)testThatItReturnsRemoteIdentifierAsTheMediumProfileImageIdentifierIfItHasACachedImage
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToMediumImageCache];
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    // when
    NSString *identifier = searchUser.imageMediumIdentifier;
    
    // then
    XCTAssertEqualObjects(identifier, searchUser.remoteIdentifier.transportString);
}

- (void)testThatItReturnsANulRemoteIdentifierAsTheMediumProfileImageIdentifierIfItHasNoCachedImage
{
    // given
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    
    // when
    NSString *identifier = searchUser.imageMediumIdentifier;
    
    // then
    XCTAssertNil(identifier);
}

- (void)testThatItReturnsMediumProfileImageIdentifierFromUserIfItHasAUser
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    user.imageMediumData = mockImage;
    user.localMediumRemoteIdentifier = [NSUUID createUUID];
    
    [self.uiMOC saveOrRollback];
    
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"hans"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:user.remoteIdentifier
                                                             user:user
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToMediumImageCache];
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    // when
    NSString *imageIdentifier = searchUser.imageMediumIdentifier;
    
    // then
    NSString *fetchedIdentifier = user.imageMediumIdentifier;
    XCTAssertEqualObjects(imageIdentifier, fetchedIdentifier);
}

- (void)testThatItStoresTheCachedMediumProfileData;
{
    // given
    NSData *mockImage = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];
    ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithName:@"foo"
                                                           handle:@"foo"
                                                      accentColor:ZMAccentColorBrightYellow
                                                         remoteID:[NSUUID createUUID]
                                                             user:nil
                                         syncManagedObjectContext:self.syncMOC
                                           uiManagedObjectContext:self.uiMOC];

    NSCache *cache = [ZMSearchUser searchUserToMediumImageCache];
    NSCache *idCache = [ZMSearchUser searchUserToMediumAssetIDCache];
    
    [cache setObject:mockImage forKey:searchUser.remoteIdentifier];
    
    NSData *dataA = [searchUser imageMediumData];
    XCTAssertNotNil(dataA);
    NSString *dataIdentifierA = [searchUser imageMediumIdentifier];
    XCTAssertNotNil(dataIdentifierA);
    SearchUserAssetObjC *asset = [[SearchUserAssetObjC alloc] initWithLegacyId:[NSUUID uuidWithTransportString:dataIdentifierA]];
    [idCache setObject:asset forKey:searchUser.remoteIdentifier];
    
    // when
    [cache removeObjectForKey:searchUser.remoteIdentifier];
    NSData *dataB = [searchUser imageMediumData];
    NSString *dataIdentifierB = [searchUser imageMediumIdentifier];
    
    // then
    AssertEqualData(dataA, dataB);
    XCTAssertEqualObjects(dataIdentifierA, dataIdentifierB);
}


@end

