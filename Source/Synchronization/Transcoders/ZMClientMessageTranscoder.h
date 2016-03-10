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


#import "ZMMessageTranscoder+Internal.h"

@class ZMClientRegistrationStatus;

@interface ZMClientMessageTranscoder : ZMMessageTranscoder

+ (instancetype)clientMessageTranscoderWithManagedObjectContext:(NSManagedObjectContext *)moc
                                    localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
                                       clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus;

@end


@class ZMUpstreamModifiedObjectSync;
@class ClientMessageRequestFactory;
@class ZMDownstreamObjectSync;

@interface ZMClientMessageTranscoder (Testing)

+ (instancetype)clientMessageTranscoderWithManagedObjectContext:(NSManagedObjectContext *)moc
                                     upstreamInsertedObjectSync:(ZMUpstreamInsertedObjectSync *)upstreamObjectSync
                                    localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
                                         messageExpirationTimer:(ZMMessageExpirationTimer *)expirationTimer
                                       clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                  upstreamInsertedObjectSync:(ZMUpstreamInsertedObjectSync *)upstreamInsertedObjectSync
                  upstreamModifiedObjectSync:(ZMUpstreamModifiedObjectSync *)upstreamModifiedObjectSync
                        downstreamObjectSync:(ZMDownstreamObjectSync *)downstreamObjectSync
                 localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
                      messageExpirationTimer:(ZMMessageExpirationTimer *)expirationTimer
                              requestFactory:(ClientMessageRequestFactory *)factory
                    clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus;;

@end
