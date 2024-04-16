//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

#import "ZMConnection+Helper.h"
#import "ZMUser+Internal.h"

@implementation ZMConnection (Helper)

+ (instancetype)insertNewSentConnectionToUser:(ZMUser *)user;
{
    VerifyReturnValue(user.connection == nil, user.connection);
    RequireString(user != nil, "Can not create a connection to <nil> user.");
    ZMConnection *connection = [self insertNewObjectInManagedObjectContext:user.managedObjectContext];
    connection.to = user;
    connection.lastUpdateDate = [NSDate date];
    connection.status = ZMConnectionStatusSent;

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:user.managedObjectContext];
    conversation.creator = [ZMUser selfUserInContext:user.managedObjectContext];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.lastModifiedDate = connection.lastUpdateDate;

    user.oneOnOneConversation = conversation;
    [conversation addParticipantAndUpdateConversationStateWithUser:user role:nil];

    return connection;
}

@end
