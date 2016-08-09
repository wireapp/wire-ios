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


@import ZMTesting;
@import CoreData;
@import ZMTransport;


@class MockUser;
@class MockEvent;
@class MockUserClient;

typedef NS_ENUM(int16_t, ZMTConversationType) {
    ZMTConversationTypeGroup = 0,
    ZMTConversationTypeSelf = 1,
    ZMTConversationTypeOneOnOne = 2,
    ZMTConversationTypeConnection = 3,
    ZMTConversationTypeInvalid = 100
};

@interface MockConversation : NSManagedObject

@property (nonatomic) NSString *archived;
@property (nonatomic) NSString *otrArchivedRef;
@property (nonatomic) NSString *otrMutedRef;
@property (nonatomic) BOOL otrArchived;
@property (nonatomic) BOOL otrMuted;

@property (nonatomic) NSString *clearedEventID;
@property (nonatomic) MockUser *creator;
@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *selfIdentifier;
@property (nonatomic) NSString *lastEvent;
@property (nonatomic) NSDate *lastEventTime;
@property (nonatomic) NSString *lastRead;
@property (nonatomic) BOOL muted;
@property (nonatomic) NSDate *mutedTime;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic) int16_t status;
@property (nonatomic) NSString *statusRef;
@property (nonatomic) NSDate *statusTime;
@property (nonatomic) ZMTConversationType type;
@property (nonatomic) BOOL callWasDropped;
/// participants that are not self
@property (nonatomic, readonly) NSOrderedSet *activeUsers;
/// participants that are not self
@property (nonatomic, readonly) NSSet *inactiveUsers;
@property (nonatomic, readonly) NSOrderedSet *callParticipants;
@property (nonatomic) NSSet *usersIgnoringCall;

@property (nonatomic, readonly) NSOrderedSet *events;
@property (nonatomic) BOOL isVideoCall;

- (id<ZMTransportData>)transportData;

+ (NSFetchRequest *)sortedFetchRequest;
+ (NSFetchRequest *)sortedFetchRequestWithPredicate:(NSPredicate *)predicate;

+ (instancetype)insertConversationIntoContext:(NSManagedObjectContext *)moc withSelfUser:(MockUser *)selfUser creator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)type;
+ (instancetype)insertConversationIntoContext:(NSManagedObjectContext *)moc creator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)type;


+ (instancetype)conversationInMoc:(NSManagedObjectContext *)moc withCreator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)type;

- (MockEvent *)insertClientMessageFromUser:(MockUser *)fromUser data:(NSData *)data;

/// Encrypts and inserts a OTR message using the gerneric message data sent from the given client to the given client
- (MockEvent *)encryptAndInsertDataFromClient:(MockUserClient *)fromClient
                                     toClient:(MockUserClient *)toClient
                                         data:(NSData *)data;

- (MockEvent *)insertOTRMessageFromClient:(MockUserClient *)fromClient
                                 toClient:(MockUserClient *)toClient
                                     data:(NSData *)data;

- (MockEvent *)insertOTRAssetFromClient:(MockUserClient *)fromClient
                               toClient:(MockUserClient *)toClient
                               metaData:(NSData *)metaData
                              imageData:(NSData *)imageData
                                assetId:(NSUUID *)assetId
                               isInline:(BOOL)isInline;

- (MockEvent *)insertKnockFromUser:(MockUser *)fromUser nonce:(NSUUID *)nonce;
- (MockEvent *)insertHotKnockFromUser:(MockUser *)fromUser nonce:(NSUUID *)nonce ref:(NSString *)eventID;
- (MockEvent *)insertTypingEventFromUser:(MockUser *)fromUser isTyping:(BOOL)isTyping;
- (MockEvent *)remotelyArchiveFromUser:(MockUser *)fromUser includeOTR:(BOOL)shouldIncludeOTR;;
- (MockEvent *)remotelyClearHistoryFromUser:(MockUser *)fromUser includeOTR:(BOOL)shouldIncludeOTR;;
- (MockEvent *)remotelyDeleteFromUser:(MockUser *)fromUser includeOTR:(BOOL)shouldIncludeOTR;;

- (void)insertImageEventsFromUser:(MockUser *)fromUser;
- (void)insertPreviewImageEventFromUser:(MockUser *)fromUser correlationID:(NSUUID *)correlationID none:(NSUUID *)nonce;
- (void)insertMediumImageEventFromUser:(MockUser *)fromUser correlationID:(NSUUID *)correlationID none:(NSUUID *)nonce;

- (void)dropCall;
- (MockEvent *)addUsersByUser:(MockUser *)byUser addedUsers:(NSArray *)addedUsers;
- (MockEvent *)removeUsersByUser:(MockUser *)byUser removedUser:(MockUser *)removedUser;
- (MockEvent *)changeNameByUser:(MockUser *)user name:(NSString *)name;
- (MockEvent *)insertAssetUploadEventForUser:(MockUser *)user data:(NSData *)data disposition:(NSDictionary *)disposition dataTypeAsMIME:(NSString *)dataTypeAsMIME assetID:(NSString *)assetID;
- (MockEvent *)connectRequestByUser:(MockUser *)byUser toUser:(MockUser *)user message:(NSString *)message;
- (MockEvent *)callEndedEventFromUser:(MockUser *)user selfUser:(MockUser *)selfUser;

- (void)ignoreCallByUser:(MockUser *)user;
- (void)addUserToCall:(MockUser *)user;
- (void)addUserToVideoCall:(MockUser *)user;
- (void)removeUserFromCall:(MockUser *)user;

@end
