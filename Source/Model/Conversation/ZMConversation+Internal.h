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


#import "ZMConversation.h"
#import "ZMManagedObject+Internal.h"
#import "ZMMessage.h"
#import "ZMConnection.h"
#import "ZMConversationSecurityLevel.h"
#import "ZMConversation+Timestamps.h"

@import WireImages;

@class ZMClientMessage;
@class ZMAssetClientMessage;
@class ZMConnection;
@class ZMUser;
@class ZMConversationMessageWindow;
@class ZMConversationList;
@class ZMLastRead;
@class ZMCleared;
@class ZMUpdateEvent;
@class ZMLocationData;
@class ZMGenericMessage;
@class ZMSystemMessage;
@class Team;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const ZMConversationConnectionKey;
extern NSString *const ZMConversationHasUnreadMissedCallKey;
extern NSString *const ZMConversationHasUnreadUnsentMessageKey;
extern NSString *const ZMConversationIsArchivedKey;
extern NSString *const ZMConversationIsSelfAnActiveMemberKey;
extern NSString *const ZMConversationIsSilencedKey;
extern NSString *const ZMConversationMessagesKey;
extern NSString *const ZMConversationHiddenMessagesKey;
extern NSString *const ZMConversationLastServerSyncedActiveParticipantsKey;
extern NSString *const ZMConversationHasUnreadKnock;
extern NSString *const ZMConversationUserDefinedNameKey;
extern NSString *const ZMVisibleWindowLowerKey;
extern NSString *const ZMVisibleWindowUpperKey;
extern NSString *const ZMIsDimmedKey;
extern NSString *const ZMNormalizedUserDefinedNameKey;
extern NSString *const ZMConversationListIndicatorKey;
extern NSString *const ZMConversationConversationTypeKey;

extern NSString *const ZMConversationLastReadServerTimeStampKey;
extern NSString *const ZMConversationLastServerTimeStampKey;
extern NSString *const ZMConversationClearedTimeStampKey;
extern NSString *const ZMConversationArchivedChangedTimeStampKey;
extern NSString *const ZMConversationSilencedChangedTimeStampKey;

extern NSString *const ZMNotificationConversationKey;
extern NSString *const ZMConversationRemoteIdentifierDataKey;


extern const NSUInteger ZMConversationMaxTextMessageLength;
extern NSTimeInterval ZMConversationDefaultLastReadTimestampSaveDelay;
extern NSString *const ZMConversationEstimatedUnreadCountKey;

extern NSString *const ZMConversationInternalEstimatedUnreadCountKey;
extern NSString *const ZMConversationLastUnreadKnockDateKey;
extern NSString *const ZMConversationLastUnreadMissedCallDateKey;
extern NSString *const ZMConversationLastReadLocalTimestampKey;

extern NSString *const SecurityLevelKey;

NS_ASSUME_NONNULL_END

@interface ZMConversation (Internal)

+ (nullable instancetype)conversationWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;
+ (nullable instancetype)conversationWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc created:(nullable BOOL *)created;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray *)participants;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants inTeam:(nullable Team *)team;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants name:(nullable NSString *)name inTeam:(nullable Team *)team;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray <ZMUser *>*)participants name:(nullable NSString *)name inTeam:(nullable Team *)team allowGuests:(BOOL)allowGuests;
+ (nullable instancetype)fetchOrCreateTeamConversationInManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipant:(nonnull ZMUser *)participant team:(nonnull Team *)team;

+ (nonnull ZMConversationList *)conversationsIncludingArchivedInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)archivedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)clearedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)conversationsExcludingArchivedInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)pendingConversationsInContext:(nonnull NSManagedObjectContext *)moc;

+ (nonnull NSPredicate *)predicateForSearchQuery:(nonnull NSString *)searchQuery team:(nullable Team *)team;
+ (nonnull NSPredicate *)predicateForSearchQuery:(nonnull NSString *)searchQuery;
+ (nonnull NSPredicate *)userDefinedNamePredicateForSearchString:(nonnull NSString *)searchString;

@property (readonly, nonatomic, nonnull) NSMutableOrderedSet *mutableLastServerSyncedActiveParticipants;

@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic, nullable) NSDate *lastServerTimeStamp;
@property (nonatomic, nullable) NSDate *lastReadServerTimeStamp;
@property (nonatomic, nullable) NSDate *clearedTimeStamp;
@property (nonatomic, nullable) NSDate *archivedChangedTimestamp;
@property (nonatomic, nullable) NSDate *silencedChangedTimestamp;

@property (nonatomic, nullable) NSUUID *remoteIdentifier;
@property (nonatomic, nullable) NSUUID *teamRemoteIdentifier;
@property (readonly, nonatomic, nonnull) NSMutableOrderedSet *mutableMessages;
@property (readonly, nonatomic, nonnull) NSOrderedSet *hiddenMessages;
@property (nonatomic, nullable) ZMConnection *connection;
@property (readonly, nonatomic) enum ZMConnectionStatus relatedConnectionState; // This is a computed property, needed for snapshoting
@property (nonatomic, nonnull) ZMUser *creator;
@property (nonatomic, nullable) NSDate *lastModifiedDate;
@property (nonatomic) ZMConversationType conversationType;
@property (nonatomic, copy, nullable) NSString *normalizedUserDefinedName;
@property (nonatomic) NSTimeInterval lastReadTimestampSaveDelay;

/// unreadTimeStamps is created on didAwakeFromFetch:
/// updated when messages are inserted and the lastReadServerTimeStamp changes
@property (nonatomic, nullable) NSMutableOrderedSet *unreadTimeStamps;

/// sorts the messages in the conversation
- (void)sortMessages;
- (void)resortMessagesWithUpdatedMessage:(nonnull ZMMessage *)message;

/**
    Appends the given message in the conversation at the proper place to keep the conversation sorted.
 
    @param message The message that should be inserted.
    @returns The index the message was inserted at in the conversation.
*/
- (NSUInteger)sortedAppendMessage:(nonnull ZMMessage *)message;

- (void)mergeWithExistingConversationWithRemoteID:(nonnull NSUUID *)remoteID;


+ (nonnull NSUUID *)selfConversationIdentifierInContext:(nonnull NSManagedObjectContext *)context;
+ (nonnull ZMConversation *)selfConversationInContext:(nonnull NSManagedObjectContext *)managedObjectContext;


- (void)updateWithMessage:(nonnull ZMMessage *)message timeStamp:(nullable NSDate *)timeStamp;

- (nullable ZMClientMessage *)appendOTRKnockMessageWithNonce:(nonnull NSUUID *)nonce;
- (nullable ZMClientMessage *)appendOTRMessageWithText:(nonnull NSString *)text nonce:(nonnull NSUUID *)nonce fetchLinkPreview:(BOOL)fetchPreview;
- (nullable ZMClientMessage *)appendOTRMessageWithLocationData:(nonnull ZMLocationData *)locationData nonce:(nonnull NSUUID *)nonce;
- (nullable ZMAssetClientMessage *)appendOTRMessageWithImageData:(nonnull NSData *)imageData nonce:(nonnull NSUUID *)nonce;
- (nullable ZMAssetClientMessage *)appendOTRMessageWithFileMetadata:(nonnull ZMFileMetadata *)fileMetadata nonce:(nonnull NSUUID *)nonce;


/// Appends a new message to the conversation.
/// @param genericMessage the generic message that should be appended
/// @param expires wether the message should expire or tried to be send infinitively
/// @param hidden wether the message should be hidden in the conversation or not
- (nullable ZMClientMessage *)appendClientMessageWithGenericMessage:(nonnull ZMGenericMessage *)genericMessage expires:(BOOL)expires hidden:(BOOL)hidden;

/// Appends a new message to the conversation.
/// @param genericMessage the generic message that should be appended
- (nullable ZMClientMessage *)appendClientMessageWithGenericMessage:(nonnull ZMGenericMessage *)genericMessage;


- (void)appendNewConversationSystemMessageIfNeeded;

- (void)deleteOlderMessages;

@end


@interface ZMConversation (SelfConversation)

/// Create and append to self conversation a ClientMessage that has generic message data built with the given data
+ (nullable ZMClientMessage *)appendSelfConversationWithGenericMessage:(nonnull ZMGenericMessage *)genericMessage managedObjectContext:(nonnull NSManagedObjectContext *)moc;

+ (nullable ZMClientMessage *)appendSelfConversationWithLastReadOfConversation:(nonnull ZMConversation *)conversation;
+ (nullable ZMClientMessage *)appendSelfConversationWithClearedOfConversation:(nonnull ZMConversation *)conversation;

+ (void)updateConversationWithZMLastReadFromSelfConversation:(nonnull ZMLastRead *)lastRead inContext:(nonnull NSManagedObjectContext *)context;
+ (void)updateConversationWithZMClearedFromSelfConversation:(nonnull ZMCleared *)cleared inContext:(nonnull NSManagedObjectContext *)context;

@end



@interface ZMConversation (ParticipantsInternal)

- (void)internalAddParticipants:(nonnull NSSet<ZMUser *> *)participants;
- (void)internalRemoveParticipants:(nonnull NSSet<ZMUser *> *)participants sender:(nonnull ZMUser *)sender;

@property (nonatomic) BOOL isSelfAnActiveMember; ///< whether the self user is an active member (as opposed to a past member)
@property (readonly, nonatomic, nonnull) NSOrderedSet<ZMUser *> *lastServerSyncedActiveParticipants;

/// Checks if the security level changed as the result of the participants change.
/// Appends or moves the security level system message.
- (void)insertOrUpdateSecurityVerificationMessageAfterParticipantsChange:(nonnull ZMSystemMessage *)participantsChange;

@end




@interface ZMConversation (ZMConversationMessageWindow)

@property (nonatomic, nullable) ZMConversationMessageWindow *messageWindow;

@end



@interface NSUUID (ZMSelfConversation)

- (BOOL)isSelfConversationRemoteIdentifierInContext:(nonnull NSManagedObjectContext *)moc;

@end



@interface ZMConversation (Optimization)

+ (void)refreshObjectsThatAreNotNeededInSyncContext:(nonnull NSManagedObjectContext *)managedObjectContext;

@end

