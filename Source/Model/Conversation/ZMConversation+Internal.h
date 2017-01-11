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
#import "ZMConversation+Trace.h"
#import "ZMManagedObject+Internal.h"
#import "ZMMessage.h"
#import "ZMConnection.h"
#import "ZMConversationSecurityLevel.h"
#import "ZMConversation+Timestamps.h"

@import zimages;

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

NS_ASSUME_NONNULL_BEGIN
extern NSString *const ZMConversationConnectionKey;
extern NSString *const ZMConversationHasUnreadMissedCallKey;
extern NSString *const ZMConversationHasUnreadUnsentMessageKey;
extern NSString *const ZMConversationIsArchivedKey;
extern NSString *const ZMConversationIsSelfAnActiveMemberKey;
extern NSString *const ZMConversationIsSilencedKey;
extern NSString *const ZMConversationMessagesKey;
extern NSString *const ZMConversationHiddenMessagesKey;
extern NSString *const ZMConversationOtherActiveParticipantsKey;
extern NSString *const ZMConversationHasUnreadKnock;
extern NSString *const ZMConversationUnsyncedActiveParticipantsKey;
extern NSString *const ZMConversationUnsyncedInactiveParticipantsKey;
extern NSString *const ZMConversationUserDefinedNameKey;
extern NSString *const ZMVisibleWindowLowerKey;
extern NSString *const ZMVisibleWindowUpperKey;
extern NSString *const ZMConversationCallParticipantsKey;
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

extern NSString *const ZMConversationIsSendingVideoKey;
extern NSString *const ZMConversationCallDeviceIsActiveKey;
extern NSString *const ZMConversationIsIgnoringCallKey;

extern NSString *const ZMConversationVoiceChannelJoinFailedNotification;
extern NSString *const ZMConversationClearTypingNotificationName;
extern NSString *const ZMConversationLastReadDidChangeNotificationName;

extern NSString *const ZMConversationRemoteIdentifierDataKey;


extern const NSUInteger ZMConversationMaxTextMessageLength;
extern NSTimeInterval ZMConversationDefaultLastReadTimestampSaveDelay;
extern NSString *const ZMConversationEstimatedUnreadCountKey;

extern NSString *const ZMConversationInternalEstimatedUnreadCountKey;
extern NSString *const ZMConversationLastUnreadKnockDateKey;
extern NSString *const ZMConversationLastUnreadMissedCallDateKey;
extern NSString *const ZMConversationLastReadLocalTimestampKey;
NS_ASSUME_NONNULL_END

@interface ZMConversation (Internal)

+ (nullable instancetype)conversationWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc;
+ (nullable instancetype)conversationWithRemoteID:(nonnull NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(nonnull NSManagedObjectContext *)moc created:(nullable BOOL *)created;
+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc withParticipants:(nonnull NSArray *)participants;

+ (nonnull NSPredicate *)predicateForConversationsIncludingArchived;
+ (nonnull NSPredicate *)predicateForArchivedConversations;
+ (nonnull NSPredicate *)predicateForClearedConversations;
+ (nonnull NSPredicate *)predicateForConversationsExcludingArchivedAndInCall;
+ (nonnull NSPredicate *)predicateForPendingConversations;
+ (nonnull NSPredicate *)predicateForConversationsWithNonIdleVoiceChannel;
+ (nonnull NSPredicate *)predicateForConversationWithActiveCalls;
+ (nonnull NSPredicate *)predicateForSharableConversations;

+ (nonnull ZMConversationList *)conversationsIncludingArchivedInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)archivedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)clearedConversationsInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)conversationsExcludingArchivedAndCallingInContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull ZMConversationList *)pendingConversationsInContext:(nonnull NSManagedObjectContext *)moc;

+ (nonnull NSPredicate *)predicateForSearchString:(nonnull NSString *)searchString;
+ (nonnull NSPredicate *)userDefinedNamePredicateForSearchString:(nonnull NSString *)searchString;


/// Returns a predicate that will match conversations which need their call state updated from the backend.
+ (nonnull NSPredicate *)predicateForNeedingCallStateToBeUpdatedFromBackend;
/// Returns a predicate that will match conversations which need their call state synced to the backend.
+ (nonnull NSPredicate *)predicateForObjectsThatNeedCallStateToBeUpdatedUpstream;
/// Returns a predicate that will match conversations which are not marked yet for being updated from the backend.
+ (nonnull NSPredicate *)predicateForUpdatingCallStateDuringSlowSync;

@property (readonly, nonatomic, nullable) NSMutableOrderedSet *mutableLastServerSyncedActiveParticipants;

@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic, nullable) NSDate *lastServerTimeStamp;
@property (nonatomic, nullable) NSDate *lastReadServerTimeStamp;
@property (nonatomic, nullable) NSDate *clearedTimeStamp;
@property (nonatomic, nullable) NSDate *archivedChangedTimestamp;
@property (nonatomic, nullable) NSDate *silencedChangedTimestamp;

@property (nonatomic, nullable) NSUUID *remoteIdentifier;
@property (readonly, nonatomic, nonnull) NSMutableOrderedSet *mutableMessages;
@property (readonly, nonatomic, nonnull) NSOrderedSet *hiddenMessages;
@property (nonatomic, nullable) ZMConnection *connection;
@property (readonly, nonatomic) enum ZMConnectionStatus relatedConnectionState; // This is a computed property, needed for snapshoting
@property (nonatomic, nonnull) ZMUser *creator;
@property (nonatomic, nullable) NSDate *lastModifiedDate;
@property (nonatomic) ZMConversationType conversationType;
@property (nonatomic, copy, nullable) NSString *normalizedUserDefinedName;
@property (nonatomic) NSTimeInterval lastReadTimestampSaveDelay;
@property (nonatomic) BOOL callStateNeedsToBeUpdatedFromBackend;


@property (nonatomic) enum ZMConversationSecurityLevel securityLevel;


/// unreadTimeStamps is created on didAwakeFromFetch:
/// updated when messages are inserted and the lastReadServerTimeStamp changes
@property (nonatomic, nullable) NSMutableOrderedSet *unreadTimeStamps;

@property (nonatomic) NSTimeInterval messageDestructionTimeout;

- (void)resetParticipantsBackToLastServerSync;

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

- (nonnull ZMClientMessage *)appendClientMessageWithData:(nonnull NSData *)data;
- (nonnull ZMClientMessage *)appendOTRKnockMessageWithNonce:(nonnull NSUUID *)nonce;
- (nonnull ZMClientMessage *)appendOTRSessionResetMessage;
- (nonnull ZMClientMessage *)appendOTRMessageWithText:(nonnull NSString *)text nonce:(nonnull NSUUID *)nonce fetchLinkPreview:(BOOL)fetchPreview;
- (nonnull ZMClientMessage *)appendOTRMessageWithLocationData:(nonnull ZMLocationData *)locationData nonce:(nonnull NSUUID *)nonce;
- (nonnull ZMAssetClientMessage *)appendOTRMessageWithImageData:(nonnull NSData *)imageData nonce:(nonnull NSUUID *)nonce;
- (nonnull ZMAssetClientMessage *)appendOTRMessageWithImageData:(nonnull NSData *)imageData nonce:(nonnull NSUUID *)nonce version3:(BOOL)version3;
- (nonnull ZMAssetClientMessage *)appendOTRMessageWithFileMetadata:(nonnull ZMFileMetadata *)fileMetadata nonce:(nonnull NSUUID *)nonce;
- (nonnull ZMAssetClientMessage *)appendOTRMessageWithFileMetadata:(nonnull ZMFileMetadata *)fileMetadata nonce:(nonnull NSUUID *)nonce version3:(BOOL)version3;


/// Appends a new message to the conversation.
/// @param genericMessage the generic message that should be appended
/// @param expires wether the message should expire or tried to be send infinitively
/// @param hidden wether the message should be hidden in the conversation or not
- (nonnull ZMClientMessage *)appendGenericMessage:(nonnull ZMGenericMessage *)genericMessage expires:(BOOL)expires hidden:(BOOL)hidden;

- (void)appendNewConversationSystemMessageIfNeeded;

- (void)deleteOlderMessages;

@end


@interface ZMConversation (SelfConversation)

/// Create and append to self conversation a ClientMessage that has generic message data built with the given data
+ (nullable ZMClientMessage *)appendSelfConversationWithGenericMessageData:(nonnull NSData *)messageData managedObjectContext:(nonnull NSManagedObjectContext *)moc;

+ (nullable ZMClientMessage *)appendSelfConversationWithLastReadOfConversation:(nonnull ZMConversation *)conversation;
+ (nullable ZMClientMessage *)appendSelfConversationWithClearedOfConversation:(nonnull ZMConversation *)conversation;

+ (void)updateConversationWithZMLastReadFromSelfConversation:(nonnull ZMLastRead *)lastRead inContext:(nonnull NSManagedObjectContext *)context;
+ (void)updateConversationWithZMClearedFromSelfConversation:(nonnull ZMCleared *)cleared inContext:(nonnull NSManagedObjectContext *)context;

@end



@interface ZMConversation (ParticipantsInternal)

- (void)internalAddParticipant:(nonnull ZMUser *)participant isAuthoritative:(BOOL)isAuthoritative;
- (void)internalRemoveParticipant:(nonnull ZMUser *)participant sender:(nonnull ZMUser *)sender;

@property (nonatomic) BOOL isSelfAnActiveMember; ///< whether the self user is an active member (as opposed to a past member)
@property (readonly, nonatomic, nonnull) NSOrderedSet<ZMUser *> *otherActiveParticipants;
@property (readonly, nonatomic, nonnull) NSMutableOrderedSet<ZMUser *> *mutableOtherActiveParticipants;

/// Removes user from unsyncedInactiveParticipants
- (void)synchronizeRemovedUser:(nonnull ZMUser *)user;

/// Removes user from unsyncedActiveParticipants
- (void)synchronizeAddedUser:(nonnull ZMUser *)user;

/// List of users which have been removed from the conversation locally but not one the backend
@property (readonly, nonatomic, nullable) NSOrderedSet<ZMUser *> *unsyncedInactiveParticipants;

/// List of users which have been added to the conversation locally but not one the backend
@property (readonly, nonatomic, nullable) NSOrderedSet<ZMUser *> *unsyncedActiveParticipants;

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

