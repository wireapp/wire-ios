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

@import ZMTransport;
@import ZMCMockTransport;
@import zmessaging;

#import "ZMUserSession.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "IntegrationTestBase.h"
#import "ZMMessage+Internal.h"
#import "ZMNotifications.h"
#import "ZMTestNotifications.h"
#import "ZMUserSession+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMConversationMessageWindow.h"
#import "ZMConversation+Internal.h"
#import "ZMConversationTranscoder+Internal.h"
#import "MockConversationWindowObserver.h"
#import "ZMVoiceChannel+Testing.h"
#import <zmessaging/zmessaging-Swift.h>
#import "ZMConnection.h"


@interface ConversationTestsBase : IntegrationTestBase

- (void)testThatItAppendsMessageToConversation:(MockConversation *)mockConversation
                                     withBlock:(NSArray *(^)(MockTransportSession<MockTransportSessionObjectCreation> *session))appendMessages
                                        verify:(void(^)(ZMConversation *))verifyConversation;

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                                    ignoreLastRead:(BOOL)ignoreLastRead
                        onRemoteMessageCreatedWith:(void(^)())createMessage
                                            verify:(void(^)(ZMConversation *))verifyConversation;

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                        onRemoteMessageCreatedWith:(void(^)())createMessage
                                verifyWithObserver:(void(^)(ZMConversation *, ConversationChangeObserver *))verifyConversation;

- (void)testThatItSendsANotificationInConversation:(MockConversation *)mockConversation
                                   afterLoginBlock:(void(^)())afterLoginBlock
                        onRemoteMessageCreatedWith:(void(^)())createMessage
                                verifyWithObserver:(void(^)(ZMConversation *, ConversationChangeObserver *))verifyConversation;

@property (nonatomic) MockConversation *groupConversationWithOnlyConnected;
@property (nonatomic) NSMutableArray *receivedConversationWindowChangeNotifications;

@end

@interface ConversationTestsBase (ConversationWindow) <ZMConversationMessageWindowObserver>

- (MockConversationWindowObserver *)windowObserverAfterLogginInAndInsertingMessagesInMockConversation:(MockConversation *)mockConversation;

@end

