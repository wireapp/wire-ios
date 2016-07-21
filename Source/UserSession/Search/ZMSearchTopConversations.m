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


@import ZMUtilities;
@import ZMCDataModel;

#import "ZMSearchTopConversations.h"



static NSString * const DateKey = @"date";
static NSString * const ConversationsKey = @"conversations";
static NSString * const RequestedConversationsCountKey = @"requestedConversationsCount";



@interface ZMSearchTopConversations ()

@property (nonatomic) NSArray *conversationObjectIDs;
@property (nonatomic) NSArray *conversationObjectIDURIs;

@end



@implementation ZMSearchTopConversations

+ (BOOL)supportsSecureCoding;
{
    return YES;
}

- (instancetype)init
{
    return [self initWithConversations:nil];
}

- (instancetype)initWithConversations:(NSArray *)conversations;
{
    self = [super init];
    if (self) {
        _creationDate = [NSDate date];
        self.conversationObjectIDs = [conversations mapWithBlock:^(ZMConversation *conversation){
            NSManagedObjectID *moid = conversation.objectID;
            return moid.isTemporaryID ? nil : moid;
        }];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _creationDate = [coder decodeObjectOfClass:NSDate.class forKey:DateKey];
        self.conversationObjectIDURIs = [coder decodeObjectOfClasses:[NSSet setWithObjects:NSURL.class, NSArray.class, nil] forKey:ConversationsKey];
        if ([coder containsValueForKey:RequestedConversationsCountKey]) {        
            _requestedConversationsCount = [coder decodeIntegerForKey:RequestedConversationsCountKey];
        }
        else {
            _requestedConversationsCount = 9;
        }
        if (self.creationDate == nil) {
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    if (self.creationDate != nil) {
        [coder encodeObject:self.creationDate forKey:DateKey];
    }
    [self createURIs];
    if (self.conversationObjectIDURIs != nil) {
        [coder encodeObject:self.conversationObjectIDURIs forKey:ConversationsKey];
    }
    
    [coder encodeInteger:self.requestedConversationsCount forKey:RequestedConversationsCountKey];
}

- (void)createURIs;
{
    if (self.conversationObjectIDURIs == nil) {
        self.conversationObjectIDURIs = [self.conversationObjectIDs mapWithBlock:^(NSManagedObjectID *moid) {
            return moid.URIRepresentation;
        }];
    }
}

- (NSString *)description
{
    NSArray *identifiers = self.conversationObjectIDURIs;
    if (identifiers == nil) {
        identifiers = [self.conversationObjectIDs mapWithBlock:^(NSManagedObjectID *moid) {
            return moid.URIRepresentation;
        }];
    }
    unsigned count = (unsigned) identifiers.count;
    return [NSString stringWithFormat:@"<%@: %p> count = %u {%@}",
            self.class, self,
            count, [identifiers componentsJoinedByString:@"; "]];
}

- (BOOL)hasConversationsIdenticalTo:(ZMSearchTopConversations *)other;
{
    if (other == nil) {
        return NO;
    }
    [self createURIs];
    [other createURIs];
    return [self.conversationObjectIDURIs isEqual:other.conversationObjectIDURIs];
}

- (NSArray *)conversationsInManagedObjectContext:(NSManagedObjectContext *)context;
{
    if (self.conversationObjectIDs == nil) {
        NSPersistentStoreCoordinator *psc = context.persistentStoreCoordinator;
        self.conversationObjectIDs = [self.conversationObjectIDURIs mapWithBlock:^(NSURL *URI) {
            return [psc managedObjectIDForURIRepresentation:URI];
        }];
        if (self.conversationObjectIDs == nil) {
            self.conversationObjectIDs = @[];
        }
    }
    // Pull objects into the context if they're not already there:
    NSArray *nonRegisteredObjectIDs = [self.conversationObjectIDs mapWithBlock:^(NSManagedObjectID *moid) {
        return ([context objectRegisteredForID:moid] == nil) ? moid : nil;
    }];
    if (0 < nonRegisteredObjectIDs.count) {
        NSFetchRequest *request = [ZMConversation sortedFetchRequestWithPredicateFormat:@"self IN %@", nonRegisteredObjectIDs];
        request.returnsObjectsAsFaults = NO;
        (void) [context executeFetchRequestOrAssert:request];
    }
    // Return those conversations that are in the context, i.e. are existing:
    return [self.conversationObjectIDs mapWithBlock:^(NSManagedObjectID *moid) {
        return [context objectRegisteredForID:moid];
    }];
}

@end



@implementation ZMSearchTopConversations (Serialization)

static NSString * const SerializationKey = @"top";

- (NSData *)encode;
{
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:self forKey:SerializationKey];
    [archiver finishEncoding];
    return data;
}

+ (instancetype)decodeFromData:(NSData *)data;
{
    if (data.length < 1) {
        return nil;
    }
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    unarchiver.requiresSecureCoding = YES;
    ZMSearchTopConversations *decoded = [unarchiver decodeObjectOfClass:ZMSearchTopConversations.class forKey:SerializationKey];
    [unarchiver finishDecoding];
    return decoded;
}

@end
