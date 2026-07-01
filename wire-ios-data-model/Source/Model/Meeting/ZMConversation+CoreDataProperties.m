//
//  ZMConversation+CoreDataProperties.m
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

#import "ZMConversation+CoreDataProperties.h"

@implementation ZMConversation (CoreDataProperties)

+ (NSFetchRequest<ZMConversation *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
}

@dynamic accessModeStrings;
@dynamic accessRoleString;
@dynamic accessRoleStringsV2;
@dynamic archivedChangedTimestamp;
@dynamic cellName;
@dynamic cellsState;
@dynamic ciphersuite;
@dynamic clearedTimeStamp;
@dynamic commitPendingProposalDate;
@dynamic conversationType;
@dynamic domain;
@dynamic draftMessageData;
@dynamic draftMessageNonce;
@dynamic effectiveConversationType;
@dynamic epoch;
@dynamic groupType;
@dynamic hasReadReceiptsEnabled;
@dynamic hasUnreadUnsentMessage;
@dynamic internalEstimatedUnreadCount;
@dynamic internalEstimatedUnreadSelfMentionCount;
@dynamic internalEstimatedUnreadSelfReplyCount;
@dynamic internalIsArchived;
@dynamic isDeletedRemotely;
@dynamic isForcedReadOnly;
@dynamic isPendingInitialFetch;
@dynamic isPendingMetadataRefresh;
@dynamic isSelfAnActiveMember;
@dynamic language;
@dynamic lastModifiedDate;
@dynamic lastReadServerTimeStamp;
@dynamic lastServerTimeStamp;
@dynamic lastUnreadKnockDate;
@dynamic lastUnreadMissedCallDate;
@dynamic legalHoldStatus;
@dynamic localMessageDestructionTimeout;
@dynamic messageProtocol;
@dynamic migratedToMLS;
@dynamic mlsGroupID;
@dynamic mlsStatus;
@dynamic mlsVerificationStatus;
@dynamic modifiedKeys;
@dynamic mutedStatus;
@dynamic needsToBeUpdatedFromBackend;
@dynamic needsToCalculateUnreadMessages;
@dynamic needsToDownloadRoles;
@dynamic needsToVerifyLegalHold;
@dynamic normalizedUserDefinedName;
@dynamic primaryKey;
@dynamic privateChannelPermission;
@dynamic remoteIdentifier;
@dynamic remoteIdentifier_data;
@dynamic securityLevel;
@dynamic silencedChangedTimestamp;
@dynamic syncedMessageDestructionTimeout;
@dynamic teamRemoteIdentifier;
@dynamic teamRemoteIdentifier_data;
@dynamic userDefinedName;
@dynamic voiceChannel;
@dynamic allMessages;
@dynamic creator;
@dynamic hiddenMessages;
@dynamic labels;
@dynamic lastServerSyncedActiveParticipants;
@dynamic nonTeamRoles;
@dynamic oneOnOneUser;
@dynamic parentMeeting;
@dynamic participantRoles;
@dynamic team;
@dynamic wireCellsMessageAttachmentDrafts;

@end
