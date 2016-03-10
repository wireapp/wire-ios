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


#import "MockTransportSession+internal.h"
#import "MockUser.h"
#import "MockUserClient.h"
@import ZMProtos;

@protocol OtrMessage <NSObject>

- (ZMClientId *)sender;

@end


@interface MockTransportSession (OTR)

- (MockUserClient *)otrMessageSender:(NSDictionary *)payload;
- (NSDictionary *)missedClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation sender:(MockUserClient *)sender;
- (NSDictionary *)redundantClients:(NSDictionary *)recipients conversation:(MockConversation *)conversation;

- (MockUserClient *)otrMessageSenderFromClientId:(ZMClientId *)sender;
- (NSDictionary *)missedClientsFromRecipients:(NSArray *)recipients conversation:(MockConversation *)conversation sender:(MockUserClient *)sender;
- (NSDictionary *)redundantClientsFromRecipients:(NSArray *)recipients conversation:(MockConversation *)conversation;


- (void)insertOTRMessageEventsToConversation:(MockConversation *)conversation
                              requestPayload:(NSDictionary *)requestPayload
                            createEventBlock:(MockEvent *(^)(MockUserClient *recipient, NSData *messageData))createEventBlock;

- (void)insertOTRMessageEventsToConversation:(MockConversation *)conversation
                           requestRecipients:(NSArray *)recipients
                            createEventBlock:(MockEvent *(^)(MockUserClient *recipient, NSData *messageData))createEventBlock;

@end
