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
@class ZMEventID;
@class ZMEventIDRangeSet;
@class ZMConnection;
@class ZMUser;
@class ZMEventIDRange;
@class ZMConversationMessageWindow;
@class ZMConversationList;
@class ZMLastRead;
@class ZMCleared;
@class ZMUpdateEvent;
@class ZMLocationData;
@class ZMGenericMessage;

extern NSString *const ZMConversationConnectionKey;
extern NSString *const ZMConversationHasUnreadMissedCallKey;
extern NSString *const ZMConversationArchivedEventIDDataKey;
extern NSString *const ZMConversationArchivedEventIDKey;
extern NSString *const ZMConversationHasUnreadUnsentMessageKey;
extern NSString *const ZMConversationIsArchivedKey;
extern NSString *const ZMConversationIsSelfAnActiveMemberKey;
extern NSString *const ZMConversationIsSilencedKey;
extern NSString *const ZMConversationMessagesKey;
extern NSString *const ZMConversationOtherActiveParticipantsKey;
extern NSString *const ZMConversationHasUnreadKnock;
extern NSString *const ZMConversationLastReadEventIDDataKey;
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

extern NSString *const ZMConversationClearedEventIDDataKey;
extern NSString *const ZMConversationClearedEventIDKey;

extern NSString *const ZMNotificationConversationKey;

extern NSString *const ZMConversationIsSendingVideoKey;
extern NSString *const ZMConversationCallDeviceIsActiveKey;
extern NSString *const ZMConversationIsIgnoringCallKey;

extern NSString *const ZMConversationWillStartFetchingMessages;
extern NSString *const ZMConversationDidFinishFetchingMessages;
extern NSString *const ZMConversationDidChangeVisibleWindowNotification;
extern NSString *const ZMConversationVoiceChannelJoinFailedNotification;
extern NSString *const ZMConversationRequestToLoadConversationEventsNotification;
extern NSString *const ZMConversationClearTypingNotificationName;
extern NSString *const ZMConversationLastReadDidChangeNotificationName;

extern NSString *const ZMConversationRemoteIdentifierDataKey;

/// Add this number of events before the window, to add a buffer of events that are already available when the UI scrolls down
extern const NSUInteger ZMLeadingEventIDWindowBleed;
extern const NSUInteger ZMConversationMaxTextMessageLength;
extern NSTimeInterval ZMConversationDefaultLastReadEventIDSaveDelay;
extern NSString *const ZMConversationEstimatedUnreadCountKey;

extern NSString *const ZMConversationInternalEstimatedUnreadCountKey;
extern NSString *const ZMConversationLastUnreadKnockDateKey;
extern NSString *const ZMConversationLastUnreadMissedCallDateKey;
extern NSString *const ZMConversationLastReadLocalTimestampKey;


@interface ZMConversation (Internal)

+ (instancetype)conversationWithRemoteID:(NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(NSManagedObjectContext *)moc;
+ (instancetype)conversationWithRemoteID:(NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(NSManagedObjectContext *)moc created:(BOOL *)created;
+ (instancetype)insertGroupConversationIntoManagedObjectContext:(NSManagedObjectContext *)moc withParticipants:(NSArray *)participants;

+ (NSPredicate *)predicateForConversationsIncludingArchived;
+ (NSPredicate *)predicateForArchivedConversations;
+ (NSPredicate *)predicateForClearedConversations;
+ (NSPredicate *)predicateForConversationsExcludingArchivedAndInCall;
+ (NSPredicate *)predicateForPendingConversations;
+ (NSPredicate *)predicateForConversationsWithNonIdleVoiceChannel;
+ (NSPredicate *)predicateForConversationWithActiveCalls;
+ (NSPredicate *)predicateForSharableConversations;

+ (ZMConversationList *)conversationsIncludingArchivedInContext:(NSManagedObjectContext *)moc;
+ (ZMConversationList *)archivedConversationsInContext:(NSManagedObjectContext *)moc;
+ (ZMConversationList *)clearedConversationsInContext:(NSManagedObjectContext *)moc;
+ (ZMConversationList *)conversationsExcludingArchivedAndCallingInContext:(NSManagedObjectContext *)moc;
+ (ZMConversationList *)pendingConversationsInContext:(NSManagedObjectContext *)moc;

+ (NSPredicate *)predicateForSearchString:(NSString *)searchString;
+ (NSPredicate *)userDefinedNamePredicateForSearchString:(NSString *)searchString;


/// Returns a predicate that will match conversations which need their call state updated from the backend.
+ (NSPredicate *)predicateForNeedingCallStateToBeUpdatedFromBackend;
/// Returns a predicate that will match conversations which need their call state synced to the backend.
+ (NSPredicate *)predicateForObjectsThatNeedCallStateToBeUpdatedUpstream;
/// Returns a predicate that will match conversations which are not marked yet for being updated from the backend.
+ (NSPredicate *)predicateForUpdatingCallStateDuringSlowSync;

@property (readonly, nonatomic) NSMutableOrderedSet *mutableLastServerSyncedActiveParticipants;

@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic) ZMEventID *lastEventID;
@property (nonatomic) ZMEventID *lastReadEventID;
@property (nonatomic, readonly) ZMEventID *archivedEventID;
@property (nonatomic) ZMEventID *clearedEventID;

@property (nonatomic) NSDate *lastServerTimeStamp;
@property (nonatomic) NSDate *lastReadServerTimeStamp;
@property (nonatomic) NSDate *clearedTimeStamp;
@property (nonatomic) NSDate *archivedChangedTimestamp;
@property (nonatomic) NSDate *silencedChangedTimestamp;

@property (nonatomic) NSUUID *remoteIdentifier;
@property (readonly, nonatomic) NSMutableOrderedSet *mutableMessages;
@property (readonly, nonatomic) NSOrderedSet *hiddenMessages;
@property (nonatomic) ZMConnection *connection;
@property (readonly, nonatomic) enum ZMConnectionStatus relatedConnectionState; // This is a computed property, needed for snapshoting
@property (nonatomic) ZMUser *creator;
@property (nonatomic) NSDate *lastModifiedDate;
@property (nonatomic) ZMConversationType conversationType;
@property (nonatomic) ZMEventIDRangeSet *downloadedMessageIDs;
@property (nonatomic, copy) NSString *normalizedUserDefinedName;
@property (nonatomic) NSTimeInterval lastReadEventIDSaveDelay;
@property (nonatomic) BOOL callStateNeedsToBeUpdatedFromBackend;


@property (nonatomic) enum ZMConversationSecurityLevel securityLevel;


/// unreadTimeStamps is created on didAwakeFromFetch:
/// updated when messages are inserted and the lastReadServerTimeStamp changes
@property (nonatomic) NSMutableOrderedSet *unreadTimeStamps;


- (void)resetParticipantsBackToLastServerSync;

/// sorts the messages in the conversation
- (void)sortMessages;
- (void)resortMessagesWithUpdatedMessage:(ZMMessage *)message;

/**
    Appends the given message in the conversation at the proper place to keep the conversation sorted.
 
    @param message The message that should be inserted.
    @returns The index the message was inserted at in the conversation.
*/
- (NSUInteger)sortedAppendMessage:(ZMMessage *)message;

- (void)mergeWithExistingConversationWithRemoteID:(NSUUID *)remoteID;


+ (NSUUID *)selfConversationIdentifierInContext:(NSManagedObjectContext *)context;
+ (ZMConversation *)selfConversationInContext:(NSManagedObjectContext *)managedObjectContext;


- (void)updateWithMessage:(ZMMessage *)message timeStamp:(NSDate *)timeStamp eventID:(ZMEventID *)eventID;

/// This method loads messages in a window when there are NO visible messages
- (void)startFetchingMessages;

- (ZMClientMessage *)appendClientMessageWithData:(NSData *)data;
- (ZMClientMessage *)appendOTRKnockMessageWithNonce:(NSUUID *)nonce;
- (ZMClientMessage *)appendOTRSessionResetMessage;
- (ZMClientMessage *)appendOTRMessageWithText:(NSString *)text nonce:(NSUUID *)nonce;
- (ZMClientMessage *)appendOTRMessageWithLocationData:(ZMLocationData *)locationData nonce:(NSUUID *)nonce;
- (ZMAssetClientMessage *)appendOTRMessageWithImageData:(NSData *)imageData nonce:(NSUUID *)nonce;
- (ZMAssetClientMessage *)appendOTRMessageWithFileMetadata:(ZMFileMetadata *)fileMetadata nonce:(NSUUID *)nonce;

/// Appends a new message to the conversation.
/// @param genericMessage: the generic message that should be appended
/// @param hidden: weather the message should be hidden in the conversation or not
- (ZMClientMessage *)appendNonExpiringGenericMessage:(ZMGenericMessage *)genericMessage hidden:(BOOL)hidden;

- (void)appendNewConversationSystemMessageIfNeeded;

- (void)deleteOlderMessages;

@end


@interface ZMConversation (SelfConversation)

/// Create and append to self conversation a ClientMessage that has generic message data built with the given data
+ (ZMClientMessage *)appendSelfConversationWithGenericMessageData:(NSData *)messageData managedObjectContext:(NSManagedObjectContext *)moc;

+ (ZMClientMessage *)appendSelfConversationWithLastReadOfConversation:(ZMConversation *)conversation;
+ (ZMClientMessage *)appendSelfConversationWithClearedOfConversation:(ZMConversation *)conversation;

+ (void)updateConversationWithZMLastReadFromSelfConversation:(ZMLastRead *)lastRead inContext:(NSManagedObjectContext *)context;
+ (void)updateConversationWithZMClearedFromSelfConversation:(ZMCleared *)cleared inContext:(NSManagedObjectContext *)context;

@end



@interface ZMConversation (ParticipantsInternal)

- (void)internalAddParticipant:(ZMUser *)participant isAuthoritative:(BOOL)isAuthoritative;
- (void)internalRemoveParticipant:(ZMUser *)participant sender:(ZMUser *)sender;

@property (nonatomic) BOOL isSelfAnActiveMember; ///< whether the self user is an active member (as opposed to a past member)
@property (readonly, nonatomic) NSOrderedSet *otherActiveParticipants;
@property (readonly, nonatomic) NSOrderedSet *otherInactiveParticipants;
@property (readonly, nonatomic) NSMutableOrderedSet *mutableOtherActiveParticipants;
@property (readonly, nonatomic) NSMutableOrderedSet *mutableOtherInactiveParticipants;

/// Removes user from unsyncedInactiveParticipants
- (void)synchronizeRemovedUser:(ZMUser *)user;

/// Removes user from unsyncedActiveParticipants
- (void)synchronizeAddedUser:(ZMUser *)user;

/// List of users which have been removed from the conversation locally but not one the backend
@property (readonly, nonatomic) NSOrderedSet *unsyncedInactiveParticipants;

/// List of users which have been added to the conversation locally but not one the backend
@property (readonly, nonatomic) NSOrderedSet *unsyncedActiveParticipants;

@end



@interface ZMConversation (DownloadedMessagesGaps)

- (void)addEventToDownloadedEvents:(ZMEventID *)eventID timeStamp:(NSDate *)timeStamp;
- (void)addEventRangeToDownloadedEvents:(ZMEventIDRange *)eventIDRange;


/// Returns the last gap in messages inside the given visible window + window bleed of 50
- (ZMEventIDRange *)lastEventIDGapForVisibleWindow:(ZMEventIDRange *)visibleWindow;

/// Returns the last gap in messages inside the entire conversation
- (ZMEventIDRange *)lastEventIDGap;


@end




@interface ZMConversation (ZMConversationMessageWindow)

@property (nonatomic) ZMConversationMessageWindow *messageWindow;

@end



@interface NSUUID (ZMSelfConversation)

- (BOOL)isSelfConversationRemoteIdentifierInContext:(NSManagedObjectContext *)moc;

@end



@interface ZMConversation (Optimization)

+ (void)refreshObjectsThatAreNotNeededInSyncContext:(NSManagedObjectContext *)managedObjectContext;

@end

