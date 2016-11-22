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


@import ZMTransport;
@import ZMUtilities;

#import "MockUser.h"
#import "MockPicture.h"

NSString *const ZMSearchUserMutualFriendsKey = @"mutual_friends";
NSString *const ZMSearchUserTotalMutualFriendsKey = @"total_mutual_friends";

@implementation MockUser

@dynamic email;
@dynamic phone;
@dynamic accentID;
@dynamic name;
@dynamic identifier;
@dynamic trackingIdentifier;
@dynamic pictures;
@dynamic password;
@dynamic connectionsFrom;
@dynamic connectionsTo;
@dynamic isEmailValidated;
@dynamic clients;
@dynamic invitations;
@dynamic isSendingVideo;
@dynamic activeCallConversations;
@dynamic ignoredCallConversation;
@dynamic handle;

- (id<ZMTransportData>)transportData;
{
    RequireString(self.accentID != 0, "Accent ID is not set");
    NSMutableDictionary *response = [(NSDictionary *)[self transportDataWhenNotConnected] mutableCopy];
    response[@"email"] = self.email ?: [NSNull null];
    response[@"phone"] = self.phone ?: [NSNull null];
    return response;
}

- (id<ZMTransportData>)transportDataWhenNotConnected;
{
    return @{
             @"accent_id": @(self.accentID),
             @"name": self.name ?: [NSNull null],
             @"id": self.identifier ?: [NSNull null],
             @"handle": self.handle ?: [NSNull null],
             @"picture": (self.pictures == nil) ? @[] : [[self.pictures mapWithSelector:@selector(transportData)] array],
             };
}

+ (NSFetchRequest *)sortedFetchRequest;
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES];
    request.sortDescriptors = @[sd];
    return request;
}

+ (NSFetchRequest *)sortedFetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [self sortedFetchRequest];
    request.predicate = predicate;
    return request;
}

- (void)awakeFromInsert
{
    if(self.accentID == 0) {
        self.accentID = 2;
    }
}

- (NSString *)mediumImageIdentifier
{
    return self.mediumImage.identifier;
}

- (NSString *)smallProfileImageIdentifier
{
    return self.smallProfileImage.identifier;
}

- (MockPicture *)smallProfileImage
{
    for(MockPicture *picture in self.pictures) {
        if([picture.info[@"tag"] isEqualToString:@"smallProfile"]) {
            return picture;
        }
    }
    return nil;
}

- (MockPicture *)mediumImage
{
    for(MockPicture *picture in self.pictures) {
        if([picture.info[@"tag"] isEqualToString:@"medium"]) {
            return picture;
        }
    }
    return nil;
}


@end
