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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import "ZMConnection+Internal.h"
#import "ZMConnection+InvitationToConnect.h"
#import "ZMUser+Internal.h"
#import "ZMEncodedNSUUIDWithTimestamp.h"
#import "ZMUser+Internal.h"
#import "ZMManagedObject+Internal.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMUserSession+Internal.h"
#import "NSURL+LaunchOptions.h"

NSString * const ZMConnectionInvitationToConnectOutgoingBaseURL = @"https://www.wire.com/c/";

uint8_t const InvitationToConnectEncodeKey[] = {
    0x64, 0x68, 0xca, 0xee, 0x5c, 0x0, 0x25, 0xf5, 0x68, 0xe4, 0xd0, 0x85, 0xf8, 0x38, 0x28, 0x6a,
    0x8a, 0x98, 0x6d, 0x2d, 0xfa, 0x67, 0x5e, 0x48, 0xa3, 0xed, 0x2a, 0xef, 0xdd, 0xaf, 0xe8, 0xc1
};
static NSTimeInterval InvitationToConnectTTL = (60 * 60 * 24 * 7) * 2; // 2 weeks
static NSString * const InvitationToConnectMessageString = @"missive.connection_request.invitation_from_link_message";
static NSString * const InvitationToConnectArrayMetadataKey = @"ZMInvitationToConnectArray";



@implementation ZMConnection (InvitationToConnect)

+ (NSData *)invitationToConnectEncryptionKey
{
    return (NSData *) dispatch_data_create(InvitationToConnectEncodeKey, sizeof(InvitationToConnectEncodeKey), dispatch_get_global_queue(0, 0), ^{});
}

+ (void)sendInvitationToConnectFromURL:(NSURL *)url managedObjectContext:(NSManagedObjectContext *)moc;
{
    RequireString(moc.zm_isSyncContext, "Managed object context is not sync context");
    ZMEncodedNSUUIDWithTimestamp *encodedUserID = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithSafeBase64EncodedToken:[url invitationToConnectToken] withEncryptionKey:[ZMConnection invitationToConnectEncryptionKey]];
    if(encodedUserID == nil) {
        return;
    }
    
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];
    if([selfUser.remoteIdentifier isEqual:encodedUserID.uuid]) {
        return;
    }
    
    ZMUser *user = [ZMUser userWithRemoteID:encodedUserID.uuid createIfNeeded:YES inContext:moc];

    ZMConnection *connection = user.connection;
    BOOL hadConnection = connection != nil;
    
    if ( ! hadConnection) {
        connection = [ZMConnection insertNewSentConnectionToUser:user];
    }
    
    if ( ! hadConnection
        || (connection.status != ZMConnectionStatusAccepted && connection.status != ZMConnectionStatusSent && connection.status != ZMConnectionStatusBlocked )
        ) {
        
        NSString *localizedString = [[NSBundle mainBundle] localizedStringForKey:InvitationToConnectMessageString value:@"" table:nil];
        connection.message = [NSString localizedStringWithFormat:localizedString, selfUser.name];
       
        if(hadConnection) {
            connection.status = ZMConnectionStatusAccepted;
            [connection setLocallyModifiedKeys:[NSSet setWithObject:ZMConnectionStatusKey]];
        }
        else {
            // need to save to have this connection also on the UI, or won't be able to display it
            [moc saveOrRollback];
        }
    }
    
    if(connection.conversation != nil) {
        [ZMUserSession requestToOpenSyncConversationOnUI:connection.conversation];
    }
}

+ (void)storeInvitationToConnectFromURL:(NSURL *)url managedObjectContext:(NSManagedObjectContext *)moc;
{
    Require(url != nil);
    RequireString(moc.zm_isSyncContext, "Managed object context is not sync context");
    NSSet *previousURLs = [moc persistentStoreMetadataForKey:InvitationToConnectArrayMetadataKey];
    if(previousURLs == nil) {
        previousURLs = [NSSet set];
    }
    
    NSSet *newURLs = [previousURLs setByAddingObject:url];
    [moc setPersistentStoreMetadata:newURLs forKey:InvitationToConnectArrayMetadataKey];
}

+ (void)processStoredInvitationsToConnectFromURLInManagedObjectContext:(NSManagedObjectContext *)moc;
{
    RequireString(moc.zm_isSyncContext, "Managed object context is not sync context");
    NSSet *storedURLs = [moc persistentStoreMetadataForKey:InvitationToConnectArrayMetadataKey];
    
    for(NSURL *url in storedURLs) {
        [self sendInvitationToConnectFromURL:url managedObjectContext:moc];
    }
    
    [moc setPersistentStoreMetadata:nil forKey:InvitationToConnectArrayMetadataKey];
    [moc saveOrRollback];
}

@end



@implementation ZMUser (InvitationToConnect)

- (NSURL *)URLForInvitationToConnect
{
    NSDate *expiration = [NSDate dateWithTimeIntervalSinceNow:InvitationToConnectTTL];
    
    ZMEncodedNSUUIDWithTimestamp *encodedIdentifier = [[ZMEncodedNSUUIDWithTimestamp alloc] initWithUUID:self.remoteIdentifier timestampDate:expiration encryptionKey:[ZMConnection invitationToConnectEncryptionKey]];
    return [encodedIdentifier URLWithEncodedUUIDWithTimestampPrefixedWithString:ZMConnectionInvitationToConnectOutgoingBaseURL];
}

@end

