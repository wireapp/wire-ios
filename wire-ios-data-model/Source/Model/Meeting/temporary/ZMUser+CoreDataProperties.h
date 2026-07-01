//
//  ZMUser+CoreDataProperties.h
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

#import "ZMUser+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ZMUser (CoreDataProperties)

+ (NSFetchRequest<ZMUser *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSNumber *accentColorValue;
@property (nullable, nonatomic, copy) NSString *analyticsIdentifier;
@property (nullable, nonatomic, copy) NSNumber *availability;
@property (nullable, nonatomic, copy) NSString *completeProfileAssetIdentifier;
@property (nullable, nonatomic, copy) NSString *domain;
@property (nullable, nonatomic, copy) NSString *emailAddress;
@property (nullable, nonatomic, copy) NSDate *expiresAt;
@property (nullable, nonatomic, copy) NSString *handle;
@property (nullable, nonatomic, copy) NSNumber *isAccountDeleted;
@property (nullable, nonatomic, copy) NSNumber *isPendingMetadataRefresh;
@property (nullable, nonatomic, retain) NSData *legalHoldRequest;
@property (nullable, nonatomic, copy) NSString *managedBy;
@property (nullable, nonatomic, retain) NSObject *modifiedKeys;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *needsPropertiesUpdate;
@property (nullable, nonatomic, copy) NSNumber *needsRichProfileUpdate;
@property (nullable, nonatomic, copy) NSNumber *needsToAcknowledgeLegalHoldStatus;
@property (nullable, nonatomic, copy) NSNumber *needsToBeUpdatedFromBackend;
@property (nullable, nonatomic, copy) NSNumber *needsToRefetchLabels;
@property (nullable, nonatomic, copy) NSString *normalizedEmailAddress;
@property (nullable, nonatomic, copy) NSString *normalizedName;
@property (nullable, nonatomic, copy) NSString *previewProfileAssetIdentifier;
@property (nullable, nonatomic, copy) NSString *primaryKey;
@property (nullable, nonatomic, copy) NSString *providerIdentifier;
@property (nullable, nonatomic, copy) NSNumber *readReceiptsEnabled;
@property (nullable, nonatomic, copy) NSNumber *readReceiptsEnabledChangedRemotely;
@property (nullable, nonatomic, retain) NSObject *remoteIdentifier;
@property (nullable, nonatomic, retain) NSData *remoteIdentifier_data;
@property (nullable, nonatomic, retain) NSData *richProfile;
@property (nullable, nonatomic, copy) NSString *serviceIdentifier;
@property (nullable, nonatomic, retain) NSObject *supportedProtocols;
@property (nullable, nonatomic, retain) NSObject *teamIdentifier;
@property (nullable, nonatomic, retain) NSData *teamIdentifier_data;
@property (nonatomic) int16_t typeValue;
@property (nullable, nonatomic, copy) NSNumber *usesCompanyLogin;
@property (nullable, nonatomic, retain) AddressBookEntry *addressBookEntry;
@property (nullable, nonatomic, retain) AppInfo *appInfo;
@property (nullable, nonatomic, retain) NSSet<UserClient *> *clients;
@property (nullable, nonatomic, retain) ZMConnection *connection;
@property (nullable, nonatomic, retain) NSSet<ZMConversation *> *conversationsCreated;
@property (nullable, nonatomic, retain) NSSet<StoredMeeting *> *createdMeetings;
@property (nullable, nonatomic, retain) NSSet<Member *> *createdTeamMembers;
@property (nullable, nonatomic, retain) NSSet<Team *> *createdTeams;
@property (nullable, nonatomic, retain) NSOrderedSet<ZMConversation *> *lastServerSyncedActiveConversations;
@property (nullable, nonatomic, retain) Member *membership;
@property (nullable, nonatomic, retain) NSSet<ZMMessage *> *messagesFailedToSendRecipient;
@property (nullable, nonatomic, retain) ZMConversation *oneOnOneConversation;
@property (nullable, nonatomic, retain) NSSet<ParticipantRole *> *participantRoles;
@property (nullable, nonatomic, retain) NSSet<Reaction *> *reactions;
@property (nullable, nonatomic, retain) NSSet<ZMSystemMessage *> *showingUserAdded;
@property (nullable, nonatomic, retain) NSSet<ZMSystemMessage *> *showingUserRemoved;
@property (nullable, nonatomic, retain) NSSet<ZMSystemMessage *> *systemMessages;

@end

@interface ZMUser (CoreDataGeneratedAccessors)

- (void)addClientsObject:(UserClient *)value;
- (void)removeClientsObject:(UserClient *)value;
- (void)addClients:(NSSet<UserClient *> *)values;
- (void)removeClients:(NSSet<UserClient *> *)values;

- (void)addConversationsCreatedObject:(ZMConversation *)value;
- (void)removeConversationsCreatedObject:(ZMConversation *)value;
- (void)addConversationsCreated:(NSSet<ZMConversation *> *)values;
- (void)removeConversationsCreated:(NSSet<ZMConversation *> *)values;

- (void)addCreatedMeetingsObject:(StoredMeeting *)value;
- (void)removeCreatedMeetingsObject:(StoredMeeting *)value;
- (void)addCreatedMeetings:(NSSet<StoredMeeting *> *)values;
- (void)removeCreatedMeetings:(NSSet<StoredMeeting *> *)values;

- (void)addCreatedTeamMembersObject:(Member *)value;
- (void)removeCreatedTeamMembersObject:(Member *)value;
- (void)addCreatedTeamMembers:(NSSet<Member *> *)values;
- (void)removeCreatedTeamMembers:(NSSet<Member *> *)values;

- (void)addCreatedTeamsObject:(Team *)value;
- (void)removeCreatedTeamsObject:(Team *)value;
- (void)addCreatedTeams:(NSSet<Team *> *)values;
- (void)removeCreatedTeams:(NSSet<Team *> *)values;

- (void)insertObject:(ZMConversation *)value inLastServerSyncedActiveConversationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLastServerSyncedActiveConversationsAtIndex:(NSUInteger)idx;
- (void)insertLastServerSyncedActiveConversations:(NSArray<ZMConversation *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLastServerSyncedActiveConversationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLastServerSyncedActiveConversationsAtIndex:(NSUInteger)idx withObject:(ZMConversation *)value;
- (void)replaceLastServerSyncedActiveConversationsAtIndexes:(NSIndexSet *)indexes withLastServerSyncedActiveConversations:(NSArray<ZMConversation *> *)values;
- (void)addLastServerSyncedActiveConversationsObject:(ZMConversation *)value;
- (void)removeLastServerSyncedActiveConversationsObject:(ZMConversation *)value;
- (void)addLastServerSyncedActiveConversations:(NSOrderedSet<ZMConversation *> *)values;
- (void)removeLastServerSyncedActiveConversations:(NSOrderedSet<ZMConversation *> *)values;

- (void)addMessagesFailedToSendRecipientObject:(ZMMessage *)value;
- (void)removeMessagesFailedToSendRecipientObject:(ZMMessage *)value;
- (void)addMessagesFailedToSendRecipient:(NSSet<ZMMessage *> *)values;
- (void)removeMessagesFailedToSendRecipient:(NSSet<ZMMessage *> *)values;

- (void)addParticipantRolesObject:(ParticipantRole *)value;
- (void)removeParticipantRolesObject:(ParticipantRole *)value;
- (void)addParticipantRoles:(NSSet<ParticipantRole *> *)values;
- (void)removeParticipantRoles:(NSSet<ParticipantRole *> *)values;

- (void)addReactionsObject:(Reaction *)value;
- (void)removeReactionsObject:(Reaction *)value;
- (void)addReactions:(NSSet<Reaction *> *)values;
- (void)removeReactions:(NSSet<Reaction *> *)values;

- (void)addShowingUserAddedObject:(ZMSystemMessage *)value;
- (void)removeShowingUserAddedObject:(ZMSystemMessage *)value;
- (void)addShowingUserAdded:(NSSet<ZMSystemMessage *> *)values;
- (void)removeShowingUserAdded:(NSSet<ZMSystemMessage *> *)values;

- (void)addShowingUserRemovedObject:(ZMSystemMessage *)value;
- (void)removeShowingUserRemovedObject:(ZMSystemMessage *)value;
- (void)addShowingUserRemoved:(NSSet<ZMSystemMessage *> *)values;
- (void)removeShowingUserRemoved:(NSSet<ZMSystemMessage *> *)values;

- (void)addSystemMessagesObject:(ZMSystemMessage *)value;
- (void)removeSystemMessagesObject:(ZMSystemMessage *)value;
- (void)addSystemMessages:(NSSet<ZMSystemMessage *> *)values;
- (void)removeSystemMessages:(NSSet<ZMSystemMessage *> *)values;

@end

NS_ASSUME_NONNULL_END
