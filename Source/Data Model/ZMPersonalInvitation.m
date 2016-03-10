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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#import "ZMPersonalInvitation.h"
#import "ZMManagedObject+Internal.h"
#import "ZMPersonalInvitation+Internal.h"
#import "ZMAddressBookContact.h"
#import "ZMAddressBook.h"
#import "NSManagedObjectContext+zmessaging.h"



static NSString *const RemoteIdentifierKey = @"remoteIdentifier";
static NSString *const RemoteIdentifierDataKey = @"remoteIdentifier_data";
static NSString *const InviteeEmailKey = @"inviteeEmail";
static NSString *const InviteePhoneNumberKey = @"inviteePhoneNumber";
static NSString *const InviteeNameKey = @"inviteeName";
static NSString *const MessageKey = @"message";
static NSString *const ServerTimestampKey = @"serverTimestamp";
static NSString *const InviterKey = @"inviter";
static NSString *const ConversationKey = @"conversation";
static NSString *const StatusKey = @"status";



@implementation ZMPersonalInvitation

@dynamic inviteeEmail;
@dynamic inviteePhoneNumber;
@dynamic inviteeName;
@dynamic message;
@dynamic serverTimestamp;
@dynamic inviter;
@dynamic conversation;
@dynamic status;

+ (NSArray *)defaultSortDescriptors;
{
    return nil;
}

+ (NSString *)entityName
{
    return @"PersonalInvitation";
}

+ (BOOL)hasLocallyModifiedDataFields
{
    return NO;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream
{
    return [NSPredicate predicateWithFormat:@"%K == NULL && %K == %lu", RemoteIdentifierDataKey, StatusKey, ZMInvitationStatusPending, nil];
}

+ (instancetype)invitationFromUser:(ZMUser *)user
                         toContact:(ZMAddressBookContact *)contact
                             email:(NSString *)email
                      conversation:(ZMConversation *)conversation
              managedObjectContext:(NSManagedObjectContext *)context
{
    ZMPersonalInvitation *invitation = [self invitationFromUser:user toContact:contact conversation:conversation managedObjectContext:context];
    invitation.inviteeEmail = email;
    [context enqueueDelayedSave];
    return invitation;
}

+ (instancetype)invitationFromUser:(ZMUser *)user
                         toContact:(ZMAddressBookContact *)contact
                       phoneNumber:(NSString *)phoneNumber
                      conversation:(ZMConversation *)conversation
              managedObjectContext:(NSManagedObjectContext *)context
{
    ZMPersonalInvitation *invitation = [self invitationFromUser:user toContact:contact conversation:conversation managedObjectContext:context];
    invitation.inviteePhoneNumber = phoneNumber;
    [context enqueueDelayedSave];
    return invitation;
}

+ (instancetype)invitationFromUser:(ZMUser *)user
                         toContact:(ZMAddressBookContact *)contact
                      conversation:(ZMConversation *)conversation
              managedObjectContext:(NSManagedObjectContext *)context
{
    ZMPersonalInvitation *invitation = (ZMPersonalInvitation *)[ZMPersonalInvitation insertNewObjectInManagedObjectContext:context];
    invitation.inviter = user;
    invitation.inviteeName = contact.name;
    invitation.conversation = conversation;
    invitation.status = ZMInvitationStatusPending;
    return invitation;
}

+ (NSFetchRequest *)fetchRequest
{
    return [NSFetchRequest fetchRequestWithEntityName:self.entityName];
}

+ (NSArray *)fetchInvitationsFromUser:(ZMUser *)user
                              contact:(ZMAddressBookContact *)contact
                 managedObjectContext:(NSManagedObjectContext *)context
{
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND ((%K IN %@) OR (%K IN %@))",
                              InviterKey, user,
                              InviteeEmailKey, contact.emailAddresses,
                              InviteePhoneNumberKey, contact.phoneNumbers,
                              nil];
    NSFetchRequest *fetchRequest = [self fetchRequest];
    fetchRequest.predicate = predicate;
    
    return [context executeFetchRequestOrAssert:fetchRequest];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *ignoredKeys = [[super ignoredKeys] mutableCopy];
        [ignoredKeys addObjectsFromArray:@[
                                           RemoteIdentifierDataKey,
                                           StatusKey,
                                           ]];
        keys = [ignoredKeys copy];
    });
    return keys;
}

- (NSUUID *)remoteIdentifier;
{
    return [self transientUUIDForKey:RemoteIdentifierKey];
}

- (void)setRemoteIdentifier:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:RemoteIdentifierKey];
}

@end

