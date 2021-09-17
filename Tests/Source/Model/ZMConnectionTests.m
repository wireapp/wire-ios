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


@import WireTransport;

#import "ModelObjectsTests.h"

#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMManagedObject+Internal.h"


@interface ZMConnection(Testing)

+ (instancetype)insertNewPendingConnectionFromUser:(ZMUser *)user;

@end

@implementation ZMConnection(Testing)

+ (instancetype)insertNewPendingConnectionFromUser:(ZMUser *)user
{
    VerifyReturnValue(user.connection == nil, user.connection);
    RequireString(user != nil, "Can not create a connection to <nil> user.");
    ZMConnection *connection = [self insertNewObjectInManagedObjectContext:user.managedObjectContext];
    connection.to = user;
    connection.lastUpdateDate = [NSDate date];
    connection.status = ZMConnectionStatusPending;
    connection.conversation = [ZMConversation insertNewObjectInManagedObjectContext:user.managedObjectContext];
    [connection.conversation addParticipantAndUpdateConversationStateWithUser:user role:nil];
    connection.conversation.creator = [ZMUser selfUserInContext:user.managedObjectContext];
    connection.conversation.conversationType = ZMConversationTypeConnection;
    connection.conversation.lastModifiedDate = connection.lastUpdateDate;
    return connection;
}

@end



@interface ZMConnectionTests : ModelObjectsTests
@end




@implementation ZMConnectionTests

- (void)testThatWeCanSetAttributesOnConnection
{
    [self checkConnectionAttributeForKey:@"status" value:@(ZMConnectionStatusAccepted)];
    [self checkConnectionAttributeForKey:@"lastUpdateDate" value:[NSDate dateWithTimeIntervalSince1970:123456789]];
    [self checkConnectionAttributeForKey:@"message" value:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit."];
}

- (void)checkConnectionAttributeForKey:(NSString *)key value:(id)value;
{
    [self checkAttributeForClass:[ZMConnection class] key:key value:value];
}

- (void)testThatItHasLocallyModifiedDataFields
{
    XCTAssertTrue([ZMConnection isTrackingLocalModifications]);
    NSEntityDescription *entity = self.uiMOC.persistentStoreCoordinator.managedObjectModel.entitiesByName[ZMConnection.entityName];
    XCTAssertNotNil(entity.attributesByName[@"modifiedKeys"]);
}

- (void)testStatusFromString
{
    XCTAssertEqual([ZMConnection statusFromString:@"accepted"], ZMConnectionStatusAccepted);
    XCTAssertEqual([ZMConnection statusFromString:@"pending"], ZMConnectionStatusPending);
    XCTAssertEqual([ZMConnection statusFromString:@"foo"], ZMConnectionStatusInvalid);
    XCTAssertEqual([ZMConnection statusFromString:@""], ZMConnectionStatusInvalid);
    XCTAssertEqual([ZMConnection statusFromString:nil], ZMConnectionStatusInvalid);
}

- (void)testThatTheMessageTextIsCopied
{
    // given
    NSString *originalValue = @"will@foo.co";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    connection.message = mutableValue;
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(connection.message, originalValue);
}

- (void)testThatItCanDeserializeItselfFromTransportData
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"accepted",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertEqualObjects(connection.lastUpdateDateInGMT, [NSDate dateWithTransportString:payload[@"last_update"]]);
        XCTAssertEqual(connection.status, [ZMConnection statusFromString:payload[@"status"]]);
        XCTAssertTrue(connection.existsOnBackend, @"Since we parsed transport data, it must exist on the backend.");
        
        NSUUID *toUUID = [payload[@"to"] UUID];
        XCTAssertEqualObjects(connection.to.remoteIdentifier, toUUID);
        
        NSUUID *conversationUUID = [payload[@"conversation"] UUID];
        XCTAssertEqualObjects(connection.conversation.remoteIdentifier, conversationUUID);
    }];
}

- (void)testThatItCreatesAConversationForAnIncomingConnection
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"pending",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertEqualObjects(connection.lastUpdateDateInGMT, [NSDate dateWithTransportString:payload[@"last_update"]]);
        XCTAssertEqual(connection.status, [ZMConnection statusFromString:payload[@"status"]]);
        XCTAssertTrue(connection.existsOnBackend, @"Since we parsed transport data, it must exist on the backend.");
        
        NSUUID *toUUID = [payload[@"to"] UUID];
        XCTAssertEqualObjects(connection.to.remoteIdentifier, toUUID);
        
        NSUUID *conversationUUID = [payload[@"conversation"] UUID];
        XCTAssertEqualObjects(connection.conversation.remoteIdentifier, conversationUUID);
        XCTAssertEqualObjects(connection.conversation.creator, connection.to);
    }];
}

- (void)testThatItDoesNotCreateNewConnectionConversationAndUserForCancelledConnection
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"cancelled",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertNil(connection);
        [ZMConnection enumerateObjectsInContext:self.syncMOC withBlock:^(__unused ZMManagedObject *obj, __unused BOOL *stop) {
            XCTAssert(NO);
        }];
        [ZMConversation enumerateObjectsInContext:self.syncMOC withBlock:^(__unused ZMManagedObject *obj, __unused BOOL *stop) {
            XCTAssert(NO);
        }];
        [ZMUser enumerateObjectsInContext:self.syncMOC withBlock:^(__unused ZMManagedObject *obj, __unused BOOL *stop) {
            XCTAssert([(ZMUser *)obj isSelfUser]);
        }];
    }];
}

- (void)testThatInsertedUserAndConversationFromANewConnectionAreMarkedAsNeedingToBeUpdated;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"pending",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertNotNil(connection);
        XCTAssertNotNil(connection.to);
        XCTAssertTrue(connection.to.needsToBeUpdatedFromBackend);
        XCTAssertNotNil(connection.conversation);
        XCTAssertTrue(connection.conversation.needsToBeUpdatedFromBackend);
    }];
}

- (void)testThatExistingUserAndConversationFromANewConnectionAreMarkedAsNeedingToBeUpdated;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *existingUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        existingUser.remoteIdentifier = NSUUID.createUUID;
        existingUser.needsToBeUpdatedFromBackend = NO;
        [self.syncMOC saveOrRollback];
        
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"pending",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": existingUser.remoteIdentifier.transportString,
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertNotNil(connection);
        XCTAssertNotNil(connection.to);
        XCTAssertTrue(connection.to.needsToBeUpdatedFromBackend);
        XCTAssertNotNil(connection.conversation);
        XCTAssertTrue(connection.conversation.needsToBeUpdatedFromBackend);
    }];
}

- (void)testThatInsertingAConnectionMarksTheExistingConversationAsNeededToBeDownloaded;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conv.remoteIdentifier = [NSUUID createUUID];
        
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"accepted",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": conv.remoteIdentifier.transportString,
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertNotNil(connection);
        XCTAssertNotNil(connection.conversation);
        XCTAssertTrue(connection.conversation.needsToBeUpdatedFromBackend);
    }];
}

- (void)testThatItReturnsNilIfMandatoryFieldsAreEmpty
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"accepted",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        for ( NSString *key in @[@"status", @"to", @"last_update"] ) {
            
            NSMutableDictionary *testedPayload = [payload mutableCopy];
            [testedPayload removeObjectForKey:key];
            
            // when
            [self performIgnoringZMLogError:^{
                ZMConnection *connection = [ZMConnection connectionFromTransportData:testedPayload managedObjectContext:self.syncMOC];
                
                // then
                XCTAssertNil(connection, @"Did not return nil for key %@", key);
            }];

        }
    }];
}


- (void)testThatAnExistingConnectionIsNotRecreated
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"accepted",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        ZMConnection *connection1 = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        ZMConnection *connection2 = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        
        // then
        __block NSUInteger count = 0;
        [ZMConnection enumerateObjectsInContext:self.syncMOC withBlock:^(ZMManagedObject *mo ZM_UNUSED, BOOL *stop ZM_UNUSED) {
            ++count;
        }];
        
        XCTAssertEqual(1u, count);
        XCTAssertEqual(connection1, connection2);
    }];
}

- (void)testThatAnExistingConnectionIsUpdatedWithNewData
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"accepted",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        NSMutableDictionary *secondPayload = [payload mutableCopy];
        secondPayload[@"message"] = @"new-message";
        
        // when
        ZMConnection *connection1 = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        ZMConnection *connection2 = [ZMConnection connectionFromTransportData:secondPayload managedObjectContext:self.syncMOC];
        
        
        // then
        __block NSUInteger count = 0;
        [ZMConnection enumerateObjectsInContext:self.syncMOC withBlock:^(ZMManagedObject *mo ZM_UNUSED, BOOL *stop ZM_UNUSED) {
            ++count;
        }];
        
        XCTAssertEqual(1u, count);
        XCTAssertEqualObjects(connection1.objectID, connection2.objectID);
        XCTAssertEqualObjects(secondPayload[@"message"], connection2.message);
    }];
}

- (void)testThatItResetsConnectionWhenItIsCancelled
{
    [self.syncMOC performGroupedBlockAndWait:^{
        NSDictionary *payload =     // expected JSON response
        @{
          @"status": @"sent",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        NSMutableDictionary *secondPayload = [payload mutableCopy];
        secondPayload[@"status"] = @"cancelled";
        
        // when
        ZMConnection *connection1 = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        ZMUser *user = connection1.to;
        XCTAssertNotNil(user);
        
        ZMConnection *connection2 = [ZMConnection connectionFromTransportData:secondPayload managedObjectContext:self.syncMOC];
        
        // then
        __block NSUInteger count = 0;
        [ZMConnection enumerateObjectsInContext:self.syncMOC withBlock:^(ZMManagedObject *mo ZM_UNUSED, BOOL *stop ZM_UNUSED) {
            ++count;
        }];
        
        XCTAssertEqual(1u, count);
        XCTAssertEqualObjects(connection2.objectID, connection1.objectID);
        XCTAssertNil(connection1.to);
        XCTAssertNil(user.connection);
        XCTAssertEqual(connection1.status, ZMConnectionStatusCancelled);
        XCTAssertEqual(connection1.conversation.conversationType, ZMConversationTypeInvalid);
    }];
}


- (void)testThatItDoesNotReturnNilForEmptyNonMandatoryFields
{

    // given
    NSDictionary *payload =     // expected JSON response
    @{
      @"status": @"accepted",
      @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
      @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
      @"last_update": @"2014-04-16T15:01:45.762Z",
      @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2"
      };
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self performIgnoringZMLogError:^{
            
            // when
            ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
            
            // then
            XCTAssertNotNil(connection);
        }];
    }];
}

- (void)testThatItDoesNotReturnNilForNullNonMandatoryFields
{

    // given
    NSDictionary *payload =     // expected JSON response
    @{
      @"status": @"accepted",
      @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
      @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
      @"last_update": @"2014-04-16T15:01:45.762Z",
      @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
      @"message": [NSNull null]
      };
    [self.syncMOC performGroupedBlockAndWait:^{
        [self performIgnoringZMLogError:^{
            
            // when
            ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
            
            // then
            XCTAssertNotNil(connection);
        }];
    }];
}

- (void)testThatItReturnsNilForInvalidToUUID
{

    // given
    NSDictionary *payload =     // expected JSON response
    @{
      @"status": @"accepted",
      @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
      @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
      @"to": @"XXXXXXXXX",
      @"last_update": @"2014-04-16T15:01:45.762Z",
      };
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self performIgnoringZMLogError:^{
            
            // when
            ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
            
            // then
            XCTAssertNil(connection);
        }];
    }];
}

- (void)testThatItReturnsNilForInvalidToUUID_ReferringToSelfUser
{

    // given
    NSUUID *selfUserUUID = [ZMUser selfUserInContext:self.uiMOC].remoteIdentifier;
    
    NSDictionary *payload =     // expected JSON response
    @{
      @"status": @"accepted",
      @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
      @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
      @"to": selfUserUUID.transportString,
      @"last_update": @"2014-04-16T15:01:45.762Z",
      };
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self performIgnoringZMLogError:^{
            
            // when
            ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
            
            // then
            XCTAssertNil(connection);
        }];
    }];
}



- (void)testThatItReturnsNilForInvalidConversationUUID
{
    
    // given
    NSDictionary *payload =     // expected JSON response
    @{
      @"status": @"accepted",
      @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
      @"to": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
      @"last_update": @"2014-04-16T15:01:45.762Z",
      @"conversation": @"XXXXXXXXX"
      };
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self performIgnoringZMLogError:^{
            
            // when
            ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
            
            // then
            XCTAssertNil(connection);
        }];
    }];
}

- (void)testThatItDoesNotCrashWithInvalidFields
{

    // given
    NSDictionary *payload =     // expected JSON response
    @{
      @"status": @"foo",
      @"from": @"eeeee",
      @"to": @44,
      @"last_update": @[],
      @"conversation": @44,
      @"message": @{}
      };
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self performIgnoringZMLogError:^{
            
            // when
            ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
            
            // then
            XCTAssertNil(connection);
        }];
    }];

}

- (void)testThatItSetsTheConversationType_Connection_ForConnectionStatus_Ignored
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload = [self validPayloadForConnectionWithStatus:@"ignored"];
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertEqual(connection.conversation.conversationType, ZMConversationTypeConnection);
    }];
}

- (void)testThatItCreatesAConversationWithConversationType_Connection_ForAutoConnectEvent;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        NSUUID *remoteID = NSUUID.createUUID;
        
        // given
        NSDictionary *payload =     // expected JSON response
        @{
          @"conversation": remoteID.transportString,
          @"time": @"2015-05-06T12:15:00.049Z",
          @"data": @{
              @"email": [NSNull null],
              @"name": [NSNull null],
              @"message": [NSNull null],
              @"recipient": NSUUID.createUUID.transportString
          },
          @"from": NSUUID.createUUID.transportString,
          @"type": @"conversation.connect-request"
          };
        
        // when
        (void) [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        ZMConversation *conversation = [ZMConversation fetchWith:remoteID in:self.syncMOC];
        
        // then
        XCTAssertNotNil(conversation);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeConnection);
    }];
}

- (void)testThatItSetsTheConversationType_Connection_ForConnectionStatus_Pending
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload = [self validPayloadForConnectionWithStatus:@"pending"];
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertEqual(connection.conversation.conversationType, ZMConversationTypeConnection);
    }];
}

- (void)testThatItSetsTheConversationType_Connection_ForConnectionStatus_Sent
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload = [self validPayloadForConnectionWithStatus:@"sent"];
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertEqual(connection.conversation.conversationType, ZMConversationTypeConnection);
    }];
}

- (void)testThatItSetsTheConversationType_Connection_ForConnectionStatus_Cancelled
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload = [self validPayloadForConnectionWithStatus:@"cancelled"];
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertEqual(connection.conversation.conversationType, ZMConversationTypeInvalid);
    }];
}

- (void)testThatItSetsTheConversationType_OneOnOne_ForConnectionStatus_Accepted
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDictionary *payload = [self validPayloadForConnectionWithStatus:@"accepted"];
        
        // when
        ZMConnection *connection = [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        
        // then
        XCTAssertEqual(connection.conversation.conversationType, ZMConversationTypeOneOnOne);
    }];
}

- (void)testThatItUpdatesTheConversationModificationDateAfterAcceptingConnection
{
    [self.syncMOC performBlockAndWait:^{
        // given
        NSDictionary *payload = [self validPayloadForConnectionWithStatus:@"accepted"];
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        sender.remoteIdentifier = [payload uuidForKey:@"to"];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        connection.conversation = conversation;
        connection.to = sender;
        
        // when
        [self performIgnoringZMLogError:^{
            [connection updateFromTransportData:payload];
        }];
        
        // then
        XCTAssertEqual(connection.conversation.lastModifiedDate, connection.lastUpdateDate);
    }];
}

- (void)testThatItReturnsTheListOfAllConnectionsInTheUserSession;
{
    // given
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]; // this is used to make sure it doesn't return all objects
    [self.uiMOC processPendingChanges];
    
    // when
    NSArray *fetchedConnections = [ZMConnection connectionsInMangedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNotNil(fetchedConnections);
    XCTAssertEqual(1u, fetchedConnections.count);
    XCTAssertNotEqual([fetchedConnections indexOfObjectIdenticalTo:connection], (NSUInteger) NSNotFound);
}

- (void)testThatItParsesStatuses
{
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConnection *connection;
        
        connection = [ZMConnection connectionFromTransportData:[self validPayloadForConnectionWithStatus:@"accepted"] managedObjectContext:self.syncMOC];
        XCTAssertEqual(connection.status, ZMConnectionStatusAccepted);
        
        connection = [ZMConnection connectionFromTransportData:[self validPayloadForConnectionWithStatus:@"blocked"] managedObjectContext:self.syncMOC];
        XCTAssertEqual(connection.status, ZMConnectionStatusBlocked);
        
        connection = [ZMConnection connectionFromTransportData:[self validPayloadForConnectionWithStatus:@"pending"] managedObjectContext:self.syncMOC];
        XCTAssertEqual(connection.status, ZMConnectionStatusPending);
        
        connection = [ZMConnection connectionFromTransportData:[self validPayloadForConnectionWithStatus:@"ignored"] managedObjectContext:self.syncMOC];
        XCTAssertEqual(connection.status, ZMConnectionStatusIgnored);
        
        connection = [ZMConnection connectionFromTransportData:[self validPayloadForConnectionWithStatus:@"sent"] managedObjectContext:self.syncMOC];
        XCTAssertEqual(connection.status, ZMConnectionStatusSent);

        connection = [ZMConnection connectionFromTransportData:[self validPayloadForConnectionWithStatus:@"cancelled"] managedObjectContext:self.syncMOC];
        XCTAssertEqual(connection.status, ZMConnectionStatusCancelled);
    }];
}

- (void)testThatAcceptingAConnectionMarksTheUserAsNeedingToBeUpdated;
{
    // given
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to.remoteIdentifier = [NSUUID createUUID];
        connection.to.needsToBeUpdatedFromBackend = NO;
        connection.status = ZMConnectionStatusPending;
        
        [self.syncMOC saveOrRollback];
        moid = connection.objectID;
    }];
    
    // when
    ZMConnection *connection = (id) [self.uiMOC objectWithID:moid];
    connection.status = ZMConnectionStatusAccepted;
    
    // then
    XCTAssertNotNil(connection.to);
    XCTAssertTrue(connection.to.needsToBeUpdatedFromBackend);
}

- (void)testThatChangingTheStatusNotifiesSearchDirectory
{
    // given
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        connection.to.remoteIdentifier = [NSUUID createUUID];
        connection.to.needsToBeUpdatedFromBackend = NO;
        connection.status = ZMConnectionStatusPending;
        
        [self.syncMOC saveOrRollback];
        moid = connection.objectID;
    }];
    
    
    // expect
    XCTestExpectation *expectation = [self expectationWithDescription:@"Notified"];
    id token = [NotificationInContext addObserverWithName:ZMConnection.invalidateTopConversationCacheNotificationName
                                       context:self.uiMOC.notificationContext
                                        object:nil
                                         queue:nil using:^(NotificationInContext * note __unused) {
                                             [expectation fulfill];
                                         }];
    
    // when
    ZMConnection *connection = (id) [self.uiMOC objectWithID:moid];
    connection.status = ZMConnectionStatusAccepted;

    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.2]);
    token = nil;
}

- (void)testThatItInsertsNewSentConnections;
{
    // given
    __block NSManagedObjectID *userMOID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.name = @"Neal Stephenson";
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"John";
        user.remoteIdentifier = [NSUUID createUUID];
        XCTAssert([self.syncMOC saveOrRollback]);
        userMOID = user.objectID;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMUser *user = (id) [self.uiMOC objectWithID:userMOID];
    
    // when
    ZMConnection *connection = [ZMConnection insertNewSentConnectionToUser:user];
    
    // then
    XCTAssertNotNil(connection);
    XCTAssertNotNil(connection.conversation);
    XCTAssertEqual(connection.conversation.conversationType, ZMConversationTypeConnection);
    XCTAssertEqual(connection.conversation.creator, selfUser);
    AssertDateIsRecent(connection.conversation.lastModifiedDate);
    NSSet *participants = [NSSet setWithObject:user];
    XCTAssertEqualObjects(connection.conversation.localParticipants, participants);
    XCTAssertFalse(connection.existsOnBackend);
    XCTAssertEqual(connection.status, ZMConnectionStatusSent);
    XCTAssertEqual(connection.to, user);
    AssertDateIsRecent(connection.lastUpdateDate);
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
}

- (void)testThatItDoesNotCreateANewSentConnectionToAUserThatAlreadyHasAConnection;
{
    // given
    __block NSManagedObjectID *userMOID;
    __block NSManagedObjectID *connectionMOID;
    __block NSManagedObjectID *conversationMOID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.name = @"Neal Stephenson";
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"John";
        user.remoteIdentifier = [NSUUID createUUID];
        user.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        user.connection.conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssert([self.syncMOC saveOrRollback]);
        userMOID = user.objectID;
        connectionMOID = user.connection.objectID;
        conversationMOID = user.connection.conversation.objectID;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    ZMUser *user = (id) [self.uiMOC objectWithID:userMOID];
    
    // when
    __block ZMConnection *connection;
    [self performIgnoringZMLogError:^{
        connection = [ZMConnection insertNewSentConnectionToUser:user];
    }];
    XCTAssertFalse(connection.hasChanges);
    XCTAssertNotNil(connection);
    XCTAssertEqualObjects(connection.objectID, connectionMOID);
    XCTAssertNotNil(connection.conversation);
    XCTAssertEqualObjects(connection.conversation.objectID, conversationMOID);
}

- (void)testThatItCanAcceptIgnoredConnection
{
    // given
    __block NSManagedObjectID *userMOID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.name = @"Neal Stephenson";
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"John";
        user.remoteIdentifier = [NSUUID createUUID];
        XCTAssert([self.syncMOC saveOrRollback]);
        userMOID = user.objectID;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    ZMUser *user = (id) [self.uiMOC objectWithID:userMOID];
    
    // when
    ZMConnection *connection = [ZMConnection insertNewPendingConnectionFromUser:user];
    
    // then
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
    [user ignore];
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqual(connection.status, ZMConnectionStatusIgnored);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
    [user connectWithMessage:@"some message"];
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqual(connection.status, ZMConnectionStatusAccepted);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
}

- (void)testThatItCanAcceptBlockedConnection
{
    // given
    __block NSManagedObjectID *userMOID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.name = @"Neal Stephenson";
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"John";
        user.remoteIdentifier = [NSUUID createUUID];
        XCTAssert([self.syncMOC saveOrRollback]);
        userMOID = user.objectID;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    ZMUser *user = (id) [self.uiMOC objectWithID:userMOID];
    
    // when
    ZMConnection *connection = [ZMConnection insertNewPendingConnectionFromUser:user];
    
    // then
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
    [user block];
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqual(connection.status, ZMConnectionStatusBlocked);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
    [user connectWithMessage:@"some message"];
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqual(connection.status, ZMConnectionStatusAccepted);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
}

- (ZMConnection *)createNewConnectionAndCancel
{
    // given
    __block NSManagedObjectID *userMOID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.name = @"Neal Stephenson";
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"John";
        user.remoteIdentifier = [NSUUID createUUID];
        XCTAssert([self.syncMOC saveOrRollback]);
        userMOID = user.objectID;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    ZMUser *user = (id) [self.uiMOC objectWithID:userMOID];
    
    // when
    ZMConnection *connection = [ZMConnection insertNewSentConnectionToUser:user];
    
    // then
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
    [connection resetLocallyModifiedKeys:[NSSet setWithObject:@"status"]];
    
    // and when
    [user cancelConnectionRequest];
    XCTAssert([self.uiMOC saveOrRollback]);
    // then
    XCTAssertEqual(connection.status, ZMConnectionStatusCancelled);
    XCTAssertEqualObjects(connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
    [connection resetLocallyModifiedKeys:[NSSet setWithObject:@"status"]];
    return connection;
}

- (void)testThatItCanResendCancelledConnectionRequest
{
    //given
    ZMConnection *connection = [self createNewConnectionAndCancel];
    ZMUser *user = connection.to;
    
    // and when
    [user connectWithMessage:@"some message"];
    XCTAssert([self.uiMOC saveOrRollback]);

    // then
    XCTAssertEqual(connection.status, ZMConnectionStatusCancelled);
    XCTAssertNil(connection.conversation);
    XCTAssertNil(connection.to);

    // and then
    XCTAssertNotEqual(user.connection, connection);
    XCTAssertEqual(user.connection.status, ZMConnectionStatusSent);
    XCTAssertEqualObjects(user.connection.keysThatHaveLocalModifications, [NSSet setWithObject:@"status"]);
}

- (void)testThatItDoesNotCreateNewConversationWhenItResendsCancelledConnectionRequest
{
    //given
    ZMConnection *connection = [self createNewConnectionAndCancel];
    ZMUser *user = connection.to;
    ZMConversation *conversation = connection.conversation;
    
    // and when
    [user connectWithMessage:@"some message"];
    XCTAssert([self.uiMOC saveOrRollback]);
    // then
    XCTAssertNotEqual(user.connection, connection);
    XCTAssertEqual(user.connection.conversation, conversation);
}

- (void)testThatItTracksOnlyStatusKey
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMConnection *connection = [ZMConnection insertNewSentConnectionToUser:user];
    
    // then
    XCTAssertEqualObjects(connection.keysTrackedForLocalModifications, [NSSet setWithObject:@"status"]);
}

- (NSDictionary *)validPayloadForConnectionWithStatus:(NSString *)status
{
    return @{
         @"status": status,
         @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
         @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
         @"last_update": @"2014-04-16T15:01:45.762Z",
         @"conversation": @"fef60427-3c53-4ac5-b971-ad5088f5a4c2",
         @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
     };
}

- (void)testThatItDoesNotTryToMergeConversationsWithTheSameRemoteIdentifier
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        sender.remoteIdentifier =[NSUUID createUUID];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        connection.conversation = conversation;
        connection.to = sender;
        
        
        // when
        NSDictionary *transportData = @{
                                        @"status": @"accepted",
                                        @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                        @"to": sender.remoteIdentifier.transportString,
                                        @"last_update": @"2014-04-16T15:01:45.762Z",
                                        @"conversation": conversation.remoteIdentifier.transportString,
                                        @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
                                        };
        
        __block ZMConnection *fetchedConnection;
        [self performIgnoringZMLogError:^{
            fetchedConnection = [ZMConnection connectionFromTransportData:transportData managedObjectContext:self.syncMOC];
        }];
        
        // then
        XCTAssertNotNil(fetchedConnection);
        XCTAssertNotNil(conversation);
        XCTAssertEqual(fetchedConnection.conversation, conversation);
        XCTAssertFalse(conversation.isZombieObject);
    }];
}

- (void)testThatItRestoresLinkToTheRightConversationFromPayload
{
    [self.syncMOC performBlockAndWait:^{
       
        // given
        NSDictionary *payload = [self validPayloadForConnectionWithStatus:@"accepted"];
        ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        sender.remoteIdentifier = [payload uuidForKey:@"to"];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        connection.conversation = conversation;
        connection.to = sender;
        
        // when
        [self performIgnoringZMLogError:^{
            [connection updateFromTransportData:payload];
        }];
        
        // then
        XCTAssertEqualObjects(connection.conversation.remoteIdentifier.transportString, payload[@"conversation"]);
    }];
}

- (void)testThatItAddsUserToTheParticipantRoleFromPayload;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *remoteID = NSUUID.createUUID;
        NSDictionary *payload =     // expected JSON response
        @{
          @"conversation": remoteID.transportString,
          @"status": @"pending",
          @"from": @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
          @"to": @"c3308f1d-82ee-49cd-897f-2a32ed9ae1d9",
          @"last_update": @"2014-04-16T15:01:45.762Z",
          @"message": @"Hi Marco C,\n\nLet's connect in Zeta.\n\nJohn"
          };
        
        // when
        (void) [ZMConnection connectionFromTransportData:payload managedObjectContext:self.syncMOC];
        ZMConversation *conversation = [ZMConversation fetchWith:remoteID in:self.syncMOC];
        
        // then
        XCTAssertNotNil(conversation);
        XCTAssertEqual(conversation.participantRoles.count, 1);
    }];
}

@end


