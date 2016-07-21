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


#import "SharedAnalyticsEvent.h"


NS_ASSUME_NONNULL_BEGIN
@implementation SharedAnalyticsEvent

- (instancetype)initWithName:(NSString *)name
                     context:(NSString *)context
                  attributes:(nullable NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        self.eventName = name;
        self.context = context;
        self.attributes = attributes;
    }
    return self;
}

#pragma mark - Serialization

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSString *name = dictionary[NSStringFromSelector(@selector(eventName))];
    NSString *context = dictionary[NSStringFromSelector(@selector(context))];
    NSDictionary *attributes = dictionary[NSStringFromSelector(@selector(attributes))];
    
    if (name != nil && [name isKindOfClass:[NSString class]] &&
        context != nil && [context isKindOfClass:[NSString class]]) {
        return [self initWithName:name context:context attributes:attributes];
    } else {
        return nil;
    }
}

- (nonnull NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dictionary = [@{
                                         NSStringFromSelector(@selector(eventName)): self.eventName,
                                         NSStringFromSelector(@selector(context)): self.context,
                                         } mutableCopy];
    if (self.attributes) {
        dictionary[NSStringFromSelector(@selector(attributes))] = self.attributes;
    }
    return dictionary;
}

@end
NS_ASSUME_NONNULL_END
