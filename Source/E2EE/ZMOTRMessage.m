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


#import "ZMOTRMessage.h"

NSString * const DeliveredKey = @"delivered";

@implementation ZMOTRMessage

@dynamic delivered;
@dynamic dataSet;
@dynamic missingRecipients;

- (NSString *)entityName;
{
    [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Function not implemented: override by subclass" userInfo:nil] raise];
    return nil;
}

- (NSSet *)ignoredKeys;
{
    NSSet *keys = [super ignoredKeys];
    return [keys setByAddingObjectsFromArray:@[DeliveredKey, ZMMessageIsExpiredKey]];
}

- (void)missesRecipient:(UserClient *)recipient
{
    [self missesRecipients:[NSSet setWithObject:recipient]];
}

- (void)missesRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] addObjectsFromArray:recipients.allObjects];
}

- (void)doesNotMissRecipient:(UserClient *)recipient
{
    [self doesNotMissRecipients:[NSSet setWithObject:recipient]];
}

- (void)doesNotMissRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] minusSet:recipients];
}

- (ZMDeliveryState)deliveryState
{
    if (self.isEncrypted) {
        //we set server time stamp in awake from insert to be able to sort messages
        //probably we need to store "deliveryTimestamp" separately and check it here
        if (self.isExpired) {
            return ZMDeliveryStateFailedToSend;
        }
        else if (self.delivered == NO) {
            return ZMDeliveryStatePending;
        }
        else {
            return ZMDeliveryStateDelivered;
        }
    }
    else {
        return [super deliveryState];
    }
}

- (void)markAsDelivered
{
    self.delivered = YES;
    [super markAsDelivered];
}

- (void)expire
{
    [super expire];
}

- (void)resend
{
    self.delivered = NO;
    [super resend];
}

@end
