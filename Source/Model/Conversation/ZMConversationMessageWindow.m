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


#import "ZMConversation+Internal.h"
#import "ZMConversationMessageWindow.h"
#import "ZMChangedIndexes.h"
#import "ZMOrderedSetState.h"
#import "ZMMessage+Internal.h"
#import "ZMOTRMessage.h"
#import <WireDataModel/WireDataModel-Swift.h>

@interface ZMConversationMessageWindow ()

@property (nonatomic, readonly) NSMutableOrderedSet *mutableMessages;

- (instancetype)initWithConversation:(ZMConversation *)conversation size:(NSUInteger)size;
- (void)recalculateMessages;

@property (nonatomic, readonly) NSUInteger activeSize;
@property (nonatomic) NSUInteger size;

@end



@implementation ZMConversationMessageWindow


- (instancetype)initWithConversation:(ZMConversation *)conversation size:(NSUInteger)size;
{
    self = [super init];
    if(self) {
        
        _conversation = conversation;
        _mutableMessages = [NSMutableOrderedSet orderedSet];
        
        self.size = size;
        
        // find last read, offset size from there
        if(conversation.lastReadMessage != nil) {
            const NSUInteger lastReadIndex = [conversation.messages indexOfObject:conversation.lastReadMessage];
            self.size = MAX(0u, conversation.messages.count - lastReadIndex - 1 + size);
        }
            
        [self recalculateMessages];
        [conversation.managedObjectContext.messageWindowObserverCenter windowWasCreated: self];
    }
    return self;
}

- (void)dealloc
{
    if (self.conversation.managedObjectContext.zm_isValidContext) {
        [self.conversation.managedObjectContext.messageWindowObserverCenter removeMessageWindow: self];
    }
}


- (NSUInteger)activeSize;
{
    return MIN(self.size, self.conversation.messages.count);
}

- (void)recalculateMessages
{
    NSOrderedSet *messages = self.conversation.messages;
    const NSUInteger numberOfMessages = self.activeSize;
    const NSRange range = NSMakeRange(messages.count - numberOfMessages, numberOfMessages);
    NSMutableOrderedSet *newMessages = [NSMutableOrderedSet orderedSetWithOrderedSet:messages range:range copyItems:NO];

    if (self.conversation.clearedTimeStamp != nil) {
        [newMessages filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ZMMessage * _Nullable message, NSDictionary<NSString *,id> * _Nullable __unused bindings) {
            return message.shouldBeDisplayed &&
                   (message.deliveryState == ZMDeliveryStatePending || [message.serverTimestamp compare:self.conversation.clearedTimeStamp] == NSOrderedDescending);
        }]];
    } else {
        [newMessages filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ZMMessage * _Nullable message, NSDictionary<NSString *,id> * _Nullable __unused bindings) {
            return message.shouldBeDisplayed;
        }]];
    }
    
    [self.mutableMessages removeAllObjects];
    [self.mutableMessages unionOrderedSet:newMessages];
}


- (NSOrderedSet *)messages
{
    return self.mutableMessages.reversedOrderedSet;
}

-(void)moveUpByMessages:(NSUInteger)amountOfMessages
{
    NSUInteger oldSize = self.activeSize;
    self.size += amountOfMessages;
    if(oldSize != self.activeSize) {
        [self recalculateMessages];
        [self.conversation.managedObjectContext.messageWindowObserverCenter windowDidScroll:self];
    }
}

-(void)moveDownByMessages:(NSUInteger)amountOfMessages
{
    NSUInteger oldSize = self.activeSize;
    self.size -= MIN(amountOfMessages, MAX(self.size, 1u) - 1u);
    if (oldSize != self.activeSize) {
        [self recalculateMessages];
    }
    
}

@end


@implementation ZMConversation (ConversationWindow)

- (ZMConversationMessageWindow *)conversationWindowWithSize:(NSUInteger)size
{
    return [[ZMConversationMessageWindow alloc] initWithConversation:self size:size];
}

@end


