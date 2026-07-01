//
//  ZMConversation+CoreDataProperties.h
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

#import "ZMConversation+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ZMConversation (CoreDataProperties)

+ (NSFetchRequest<ZMConversation *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, retain) NSObject *accessModeStrings;
@property (nullable, nonatomic, copy) NSString *accessRoleString;
@property (nullable, nonatomic, retain) NSObject *accessRoleStringsV2;
@property (nullable, nonatomic, copy) NSDate *archivedChangedTimestamp;
@property (nullable, nonatomic, copy) NSString *cellName;
@property (nonatomic) int16_t cellsState;
@property (nullable, nonatomic, copy) NSNumber *ciphersuite;
@property (nullable, nonatomic, copy) NSDate *clearedTimeStamp;
@property (nullable, nonatomic, copy) NSDate *commitPendingProposalDate;
@property (nullable, nonatomic, copy) NSNumber *conversationType;
@property (nullable, nonatomic, copy) NSString *domain;
@property (nullable, nonatomic, retain) NSData *draftMessageData;
@property (nullable, nonatomic, retain) NSData *draftMessageNonce;
@property (nullable, nonatomic, copy) NSNumber *effectiveConversationType;
@property (nullable, nonatomic, copy) NSNumber *epoch;
@property (nullable, nonatomic, copy) NSNumber *groupType;
@property (nullable, nonatomic, copy) NSNumber *hasReadReceiptsEnabled;
@property (nullable, nonatomic, copy) NSNumber *hasUnreadUnsentMessage;
@property (nullable, nonatomic, copy) NSNumber *internalEstimatedUnreadCount;
@property (nullable, nonatomic, copy) NSNumber *internalEstimatedUnreadSelfMentionCount;
@property (nullable, nonatomic, copy) NSNumber *internalEstimatedUnreadSelfReplyCount;
@property (nullable, nonatomic, copy) NSNumber *internalIsArchived;
@property (nullable, nonatomic, copy) NSNumber *isDeletedRemotely;
@property (nullable, nonatomic, copy) NSNumber *isForcedReadOnly;
@property (nonatomic) BOOL isPendingInitialFetch;
@property (nullable, nonatomic, copy) NSNumber *isPendingMetadataRefresh;
@property (nullable, nonatomic, copy) NSNumber *isSelfAnActiveMember;
@property (nullable, nonatomic, copy) NSString *language;
@property (nullable, nonatomic, copy) NSDate *lastModifiedDate;
@property (nullable, nonatomic, copy) NSDate *lastReadServerTimeStamp;
@property (nullable, nonatomic, copy) NSDate *lastServerTimeStamp;
@property (nullable, nonatomic, copy) NSDate *lastUnreadKnockDate;
@property (nullable, nonatomic, copy) NSDate *lastUnreadMissedCallDate;
@property (nullable, nonatomic, copy) NSNumber *legalHoldStatus;
@property (nullable, nonatomic, copy) NSNumber *localMessageDestructionTimeout;
@property (nullable, nonatomic, copy) NSNumber *messageProtocol;
@property (nonatomic) BOOL migratedToMLS;
@property (nullable, nonatomic, retain) NSData *mlsGroupID;
@property (nullable, nonatomic, copy) NSNumber *mlsStatus;
@property (nonatomic) int16_t mlsVerificationStatus;
@property (nullable, nonatomic, retain) NSObject *modifiedKeys;
@property (nullable, nonatomic, copy) NSNumber *mutedStatus;
@property (nullable, nonatomic, copy) NSNumber *needsToBeUpdatedFromBackend;
@property (nullable, nonatomic, copy) NSNumber *needsToCalculateUnreadMessages;
@property (nullable, nonatomic, copy) NSNumber *needsToDownloadRoles;
@property (nullable, nonatomic, copy) NSNumber *needsToVerifyLegalHold;
@property (nullable, nonatomic, copy) NSString *normalizedUserDefinedName;
@property (nullable, nonatomic, copy) NSString *primaryKey;
@property (nonatomic) int16_t privateChannelPermission;
@property (nullable, nonatomic, retain) NSObject *remoteIdentifier;
@property (nullable, nonatomic, retain) NSData *remoteIdentifier_data;
@property (nullable, nonatomic, copy) NSNumber *securityLevel;
@property (nullable, nonatomic, copy) NSDate *silencedChangedTimestamp;
@property (nullable, nonatomic, copy) NSNumber *syncedMessageDestructionTimeout;
@property (nullable, nonatomic, retain) NSObject *teamRemoteIdentifier;
@property (nullable, nonatomic, retain) NSData *teamRemoteIdentifier_data;
@property (nullable, nonatomic, copy) NSString *userDefinedName;
@property (nullable, nonatomic, retain) NSObject *voiceChannel;
@property (nullable, nonatomic, retain) NSSet<ZMMessage *> *allMessages;
@property (nullable, nonatomic, retain) ZMUser *creator;
@property (nullable, nonatomic, retain) NSSet<ZMMessage *> *hiddenMessages;
@property (nullable, nonatomic, retain) NSSet<Label *> *labels;
@property (nullable, nonatomic, retain) NSOrderedSet<ZMUser *> *lastServerSyncedActiveParticipants;
@property (nullable, nonatomic, retain) NSSet<Role *> *nonTeamRoles;
@property (nullable, nonatomic, retain) ZMUser *oneOnOneUser;
@property (nullable, nonatomic, retain) StoredMeeting *parentMeeting;
@property (nullable, nonatomic, retain) NSSet<ParticipantRole *> *participantRoles;
@property (nullable, nonatomic, retain) Team *team;
@property (nullable, nonatomic, retain) NSSet<WireCellsMessageAttachmentDraftEntity *> *wireCellsMessageAttachmentDrafts;

@end

@interface ZMConversation (CoreDataGeneratedAccessors)

- (void)addAllMessagesObject:(ZMMessage *)value;
- (void)removeAllMessagesObject:(ZMMessage *)value;
- (void)addAllMessages:(NSSet<ZMMessage *> *)values;
- (void)removeAllMessages:(NSSet<ZMMessage *> *)values;

- (void)addHiddenMessagesObject:(ZMMessage *)value;
- (void)removeHiddenMessagesObject:(ZMMessage *)value;
- (void)addHiddenMessages:(NSSet<ZMMessage *> *)values;
- (void)removeHiddenMessages:(NSSet<ZMMessage *> *)values;

- (void)addLabelsObject:(Label *)value;
- (void)removeLabelsObject:(Label *)value;
- (void)addLabels:(NSSet<Label *> *)values;
- (void)removeLabels:(NSSet<Label *> *)values;

- (void)insertObject:(ZMUser *)value inLastServerSyncedActiveParticipantsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLastServerSyncedActiveParticipantsAtIndex:(NSUInteger)idx;
- (void)insertLastServerSyncedActiveParticipants:(NSArray<ZMUser *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLastServerSyncedActiveParticipantsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLastServerSyncedActiveParticipantsAtIndex:(NSUInteger)idx withObject:(ZMUser *)value;
- (void)replaceLastServerSyncedActiveParticipantsAtIndexes:(NSIndexSet *)indexes withLastServerSyncedActiveParticipants:(NSArray<ZMUser *> *)values;
- (void)addLastServerSyncedActiveParticipantsObject:(ZMUser *)value;
- (void)removeLastServerSyncedActiveParticipantsObject:(ZMUser *)value;
- (void)addLastServerSyncedActiveParticipants:(NSOrderedSet<ZMUser *> *)values;
- (void)removeLastServerSyncedActiveParticipants:(NSOrderedSet<ZMUser *> *)values;

- (void)addNonTeamRolesObject:(Role *)value;
- (void)removeNonTeamRolesObject:(Role *)value;
- (void)addNonTeamRoles:(NSSet<Role *> *)values;
- (void)removeNonTeamRoles:(NSSet<Role *> *)values;

- (void)addParticipantRolesObject:(ParticipantRole *)value;
- (void)removeParticipantRolesObject:(ParticipantRole *)value;
- (void)addParticipantRoles:(NSSet<ParticipantRole *> *)values;
- (void)removeParticipantRoles:(NSSet<ParticipantRole *> *)values;

- (void)addWireCellsMessageAttachmentDraftsObject:(WireCellsMessageAttachmentDraftEntity *)value;
- (void)removeWireCellsMessageAttachmentDraftsObject:(WireCellsMessageAttachmentDraftEntity *)value;
- (void)addWireCellsMessageAttachmentDrafts:(NSSet<WireCellsMessageAttachmentDraftEntity *> *)values;
- (void)removeWireCellsMessageAttachmentDrafts:(NSSet<WireCellsMessageAttachmentDraftEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
