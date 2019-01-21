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


#import "ZMTaskIdentifier.h"


static NSString * const IdentifierKey = @"identifier";

@interface ZMTaskIdentifier ()

@property (nonatomic, readwrite) NSUInteger identifier;

@end


@implementation ZMTaskIdentifier

+ (instancetype)identifierWithIdentifier:(NSUInteger)identifier;
{
    return [[self alloc] initWithIdentifier:identifier];
}

- (instancetype)initWithIdentifier:(NSUInteger)identifier;
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
    }
    return self;
}

+ (instancetype)identifierFromData:(NSData *)data
{
    if (nil == data) {
        return nil;
    }
    
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([object isKindOfClass:self]) {
        return object;
    }
    
    return nil;
}

- (NSData *)data
{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)other
{
    if (! [other isKindOfClass:self.class]) {
        return NO;
    }
    ZMTaskIdentifier *otherIdentifier = (ZMTaskIdentifier *)other;
    return self.identifier == otherIdentifier.identifier;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.identifier = [[decoder decodeObjectForKey:IdentifierKey] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:@(self.identifier) forKey:IdentifierKey];
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> identifier: %lu",
            self.class, self, (unsigned long)self.identifier];
}

@end
