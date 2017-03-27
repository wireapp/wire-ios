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


#import "MockPersonalInvitation.h"
#import <ZMCMockTransport/ZMCMockTransport-Swift.h>
@import ZMTesting;

@implementation MockPersonalInvitation

@dynamic identifier;
@dynamic inviteeEmail;
@dynamic inviteeName;
@dynamic inviteePhone;
@dynamic creationDate;
@dynamic inviter;

+ (instancetype)invitationInMOC:(NSManagedObjectContext *)MOC fromUser:(MockUser *)user toInviteeWithName:(NSString *)name email:(nullable NSString *)email phoneNumber:(nullable NSString *)phone;
{
    Require((email == nil && phone != nil) || (email != nil && phone == nil));
    
    MockPersonalInvitation *invitation = [NSEntityDescription insertNewObjectForEntityForName:@"PersonalInvitation" inManagedObjectContext:MOC];
    invitation.identifier = [NSUUID createUUID].transportString;
    invitation.inviter = user;
    invitation.inviteeName = name;
    invitation.inviteePhone = phone;
    invitation.inviteeEmail = email;
    invitation.creationDate = [NSDate date];
    
    return invitation;
}

+ (NSFetchRequest *)sortedFetchRequest;
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonalInvitation"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    return fetchRequest;
}

+ (NSFetchRequest *)sortedFetchRequestWithPredicate:(NSPredicate *)predicate;
{
    NSFetchRequest *fetchRequest = [self sortedFetchRequest];
    fetchRequest.predicate = predicate;
    return fetchRequest;
}

- (id<ZMTransportData>)transportData;
{
    return @{@"id" : self.identifier,
             @"created_at" : [self.creationDate transportString],
             @"inviter" : self.inviter.identifier,
             @"name" : self.inviteeName,
             @"email" : self.inviteeEmail ?: [NSNull null],
             @"phone" : self.inviteePhone ?: [NSNull null],
             };
             
}
@end
