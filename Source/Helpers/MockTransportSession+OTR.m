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


#import "MockTransportSession+OTR.h"
#import <WireMockTransport/WireMockTransport-Swift.h>


@implementation MockTransportSession (OTR)

- (MockUserClient *)otrMessageSender:(NSDictionary *)payload
{
    NSString *senderClientId = payload[@"sender"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", senderClientId];
    MockUserClient *client = [self.managedObjectContext executeFetchRequestOrAssert:request].firstObject;
    return client;
}

- (NSDictionary *)missedClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    return [self missedClients:recipients users:conversation.activeUsers.set sender:sender onlyForUserId:onlyForUserId];
}

- (NSDictionary *)missedClients:(NSDictionary *)recipients sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    return [self missedClients:recipients users:self.selfUser.connectionsAndTeamMembers sender:sender onlyForUserId:onlyForUserId];
}

- (NSDictionary *)missedClients:(NSDictionary *)recipients users:(NSSet<MockUser *> *)users sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    NSMutableDictionary *missedClients = [NSMutableDictionary new];
    for (MockUser *user in users) {
        if (onlyForUserId != nil && ![[NSUUID uuidWithTransportString:user.identifier] isEqual:[NSUUID uuidWithTransportString:onlyForUserId]]) {
            continue;
        }
        NSArray *recipientClients = [recipients[user.identifier] allKeys];
        NSSet *userClients = [user.clients mapWithBlock:^id(MockUserClient *client) {
            if (client != sender) {
                return client.identifier;
            }
            return nil;
        }];
        
        NSMutableSet *userMissedClients = [userClients mutableCopy];
        [userMissedClients minusSet:[NSSet setWithArray:recipientClients]];
        if (userMissedClients.count > 0) {
            missedClients[user.identifier] = userMissedClients.allObjects;
        }
    }
    return missedClients;
}

- (NSDictionary *)redundantClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation
{
    return [self redundantClients:recipients users:conversation.activeUsers.set];
}

- (NSDictionary *)redundantClients:(NSDictionary *)recipients
{
    return [self redundantClients:recipients users:self.selfUser.connectionsAndTeamMembers];
}

- (NSDictionary *)redundantClients:(NSDictionary *)recipients users:(NSSet<MockUser *> *)users
{
    NSMutableDictionary *redundantClients = [NSMutableDictionary new];
    for (NSString *userId in recipients) {
        NSDictionary *recipientPayload = recipients[userId];
        MockUser *user = [users filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", userId]].anyObject;
        NSArray *recipientClients = [recipientPayload allKeys];
        NSSet *userClients = [user.clients mapWithBlock:^id(MockUserClient *client) {
            return client.identifier;
        }];
        NSMutableSet *redundantUserClients = [NSMutableSet setWithArray:recipientClients];
        [redundantUserClients minusSet:userClients];
        if (redundantUserClients.count > 0) {
            redundantClients[userId] = redundantUserClients.allObjects;
        }
    }
    return redundantClients;
}

- (MockUserClient *)otrMessageSenderFromClientId:(ZMClientId *)sender
{
    NSString *senderClientId = [NSString stringWithFormat:@"%llx", [@(sender.client) longLongValue]];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", senderClientId];
    MockUserClient *client = [self.managedObjectContext executeFetchRequestOrAssert:request].firstObject;
    return client;
}

- (NSDictionary *)missedClientsFromRecipients:(NSArray *)recipients conversation:(MockConversation *)conversation sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    return [self missedClientsFromRecipients:recipients users:conversation.activeUsers.set sender:sender onlyForUserId:onlyForUserId];
}

- (NSDictionary *)missedClientsFromRecipients:(NSArray *)recipients sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    return [self missedClientsFromRecipients:recipients users:self.selfUser.connectionsAndTeamMembers sender:sender onlyForUserId:onlyForUserId];
}

- (NSDictionary *)missedClientsFromRecipients:(NSArray *)recipients users:(NSSet<MockUser *> *)users sender:(MockUserClient *)sender onlyForUserId:(NSString *)onlyForUserId
{
    NSMutableDictionary *missedClients = [NSMutableDictionary new];

    for (MockUser *user in users) {
        if (onlyForUserId != nil && ![[NSUUID uuidWithTransportString:user.identifier] isEqual:[NSUUID uuidWithTransportString:onlyForUserId]]) {
            continue;
        }
        ZMUserEntry *userEntry = [[recipients filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ZMUserEntry  * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable __unused bindings) {
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:evaluatedObject.user.uuid.bytes];
            NSUUID *userId = [NSUUID uuidWithTransportString:user.identifier];
            return [uuid isEqual:userId] && (onlyForUserId == nil || [[NSUUID uuidWithTransportString:onlyForUserId] isEqual:userId]);
        }]] firstObject];
        
        NSArray *recipientClients = [userEntry.clients mapWithBlock:^id(ZMClientEntry *clientEntry) {
            return [NSString stringWithFormat:@"%llx", [@(clientEntry.client.client) unsignedLongLongValue]];
        }];
        
        NSSet *userClients = [user.clients mapWithBlock:^id(MockUserClient *client) {
            if (client != sender) {
                return client.identifier;
            }
            return nil;
        }];
        
        NSMutableSet *userMissedClients = [userClients mutableCopy];
        [userMissedClients minusSet:[NSSet setWithArray:recipientClients]];
        if (userMissedClients.count > 0) {
            missedClients[user.identifier] = userMissedClients.allObjects;
        }
    }
    return missedClients;
}

- (NSDictionary *)redundantClientsFromRecipients:(NSArray *)recipients conversation:(MockConversation *)conversation
{
    return [self redundantClientsFromRecipients:recipients users:conversation.activeUsers.set];
}

- (NSDictionary *)redundantClientsFromRecipients:(NSArray *)recipients
{
    return [self redundantClientsFromRecipients:recipients users:self.selfUser.connectionsAndTeamMembers];
}

- (NSDictionary *)redundantClientsFromRecipients:(NSArray *)recipients users:(NSSet<MockUser *> *)users
{
    NSMutableDictionary *redundantClients = [NSMutableDictionary new];
    
    for (MockUser *user in users) {
        ZMUserEntry *userEntry = [[recipients filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ZMUserEntry  * _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable __unused bindings) {
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:evaluatedObject.user.uuid.bytes];
            NSUUID *userId = [NSUUID uuidWithTransportString:user.identifier];
            return [uuid isEqual:userId];
        }]] firstObject];
        
        NSArray *recipientClients = [userEntry.clients mapWithBlock:^id(ZMClientEntry *clientEntry) {
            return [NSString stringWithFormat:@"%llx", [@(clientEntry.client.client) unsignedLongLongValue]];
        }];
        
        NSSet *userClients = [user.clients mapWithBlock:^id(MockUserClient *client) {
            return client.identifier;
        }];
        
        NSMutableSet *redundantUserClients = [NSMutableSet setWithArray:recipientClients];
        [redundantUserClients minusSet:userClients];
        if (redundantUserClients.count > 0) {
            redundantClients[user.identifier] = redundantUserClients.allObjects;
        }
    }
    return redundantClients;
}

- (void)insertOTRMessageEventsToConversation:(MockConversation *)conversation
                              requestPayload:(NSDictionary *)requestPayload
                            createEventBlock:(MockEvent *(^)(MockUserClient *recipient, NSData *messageData))createEventBlock
{
    NSDictionary *recipients = requestPayload[@"recipients"];
    
    NSArray *activeClients = [conversation.activeUsers.array flattenWithBlock:^NSArray *(MockUser *user) {
        return user.clients.allObjects;
    }];
    
    for (MockUserClient *activeClient in activeClients) {
        NSString *keyPath = [NSString stringWithFormat:@"%@.%@", activeClient.user.identifier, activeClient.identifier];
        NSString *messageContent = [recipients valueForKeyPath:keyPath];
        if (messageContent == nil) {
            continue;
        }
        NSData *messageData = [[NSData alloc] initWithBase64EncodedString:messageContent options:0];
        createEventBlock(activeClient, messageData);
    }
}

- (void)insertOTRMessageEventsToConversation:(MockConversation *)conversation
                           requestRecipients:(NSArray *)recipients
                                senderClient:(MockUserClient *)senderClient
                            createEventBlock:(MockEvent *(^)(MockUserClient *recipient, NSData *messageData, NSData *decryptedData))createEventBlock;
{
    NSArray *activeClients = [conversation.activeUsers.array flattenWithBlock:^NSArray *(MockUser *user) {
        return [user.clients.allObjects mapWithBlock:^id(MockUserClient *client) {
            return client.identifier;
        }];
    }];
    
    NSFetchRequest *allClientsRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
    allClientsRequest.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", activeClients];
    NSArray *allClients = [self.managedObjectContext executeFetchRequestOrAssert:allClientsRequest];
    
    NSArray *clientsEntries = [recipients flattenWithBlock:^NSArray *(ZMUserEntry *userEntry) {
        return userEntry.clients;
    }];
    
    for (ZMClientEntry *clientEntry in clientsEntries) {
        MockUserClient *client = [[allClients filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(MockUserClient * _Nonnull aClient, NSDictionary<NSString *,id> * _Nullable __unused bindings) {
            NSString *clientId = [NSString stringWithFormat:@"%llx", [@(clientEntry.client.client) unsignedLongLongValue]];
            return [aClient.identifier isEqual:clientId];
        }]] firstObject];

        if (client != nil) {
            createEventBlock(client, clientEntry.text, [MockUserClient decryptMessageWithData:clientEntry.text from:senderClient to:client]);
        }
    }
}

@end


@implementation ZMNewOtrMessage (OtrMessage)
@end

@implementation ZMOtrAssetMeta (OtrMessage)
@end
