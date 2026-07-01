//
//  ZMUser+CoreDataProperties.m
//  
//
//  Created by Christoph Aldrian on 01.07.26.
//
//  This file was automatically generated and should not be edited.
//

#import "ZMUser+CoreDataProperties.h"

@implementation ZMUser (CoreDataProperties)

+ (NSFetchRequest<ZMUser *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"User"];
}

@dynamic accentColorValue;
@dynamic analyticsIdentifier;
@dynamic availability;
@dynamic completeProfileAssetIdentifier;
@dynamic domain;
@dynamic emailAddress;
@dynamic expiresAt;
@dynamic handle;
@dynamic isAccountDeleted;
@dynamic isPendingMetadataRefresh;
@dynamic legalHoldRequest;
@dynamic managedBy;
@dynamic modifiedKeys;
@dynamic name;
@dynamic needsPropertiesUpdate;
@dynamic needsRichProfileUpdate;
@dynamic needsToAcknowledgeLegalHoldStatus;
@dynamic needsToBeUpdatedFromBackend;
@dynamic needsToRefetchLabels;
@dynamic normalizedEmailAddress;
@dynamic normalizedName;
@dynamic previewProfileAssetIdentifier;
@dynamic primaryKey;
@dynamic providerIdentifier;
@dynamic readReceiptsEnabled;
@dynamic readReceiptsEnabledChangedRemotely;
@dynamic remoteIdentifier;
@dynamic remoteIdentifier_data;
@dynamic richProfile;
@dynamic serviceIdentifier;
@dynamic supportedProtocols;
@dynamic teamIdentifier;
@dynamic teamIdentifier_data;
@dynamic typeValue;
@dynamic usesCompanyLogin;
@dynamic addressBookEntry;
@dynamic appInfo;
@dynamic clients;
@dynamic connection;
@dynamic conversationsCreated;
@dynamic createdMeetings;
@dynamic createdTeamMembers;
@dynamic createdTeams;
@dynamic lastServerSyncedActiveConversations;
@dynamic membership;
@dynamic messagesFailedToSendRecipient;
@dynamic oneOnOneConversation;
@dynamic participantRoles;
@dynamic reactions;
@dynamic showingUserAdded;
@dynamic showingUserRemoved;
@dynamic systemMessages;

@end
