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


#import "AggregateArray.h"



@interface AggregateArray ()
@property (nonatomic, strong) NSArray* sections;
@end



@implementation AggregateArray

- (instancetype)initWithSections:(NSArray *)sections
{
    self = [super init];
    if (nil != self) {
         self.sections = sections;
    }
    return self;
}

+ (instancetype)aggregateArrayWithSections:(NSArray *)array
{
    AggregateArray *aggregate = [[self.class alloc] initWithSections:array];
    return aggregate;
}

#pragma mark - Enumeration

- (void)enumerateItems:(void(^)(NSArray *section, NSUInteger sectionIndex, id<NSObject> item, NSUInteger itemIndex, BOOL *stop))enumerator;
{
    [self enumerateSections:^(NSArray *section, NSUInteger sectionIndex, BOOL *stop) {
        NSUInteger numItems = [section count];

        for (NSUInteger item = 0; item < numItems; item++) {
            enumerator(section, sectionIndex, section[item], item, stop);
        }
    }];
}

- (void)enumerateSections:(void(^)(NSArray *section, NSUInteger sectionIndex, BOOL *stop))enumerator
{
    NSUInteger index = 0;
    for (NSArray *section in self.sections) {
        BOOL shouldStop = NO;
        enumerator(section, index, &shouldStop);
        if (shouldStop) {
            return;
        }
        index++;
    }
}

#pragma mark - Public interface

- (NSUInteger)itemCount
{
    NSUInteger __block total = 0;
    [self enumerateSections:^(NSArray *section, NSUInteger sectionIndex, BOOL *stop) {
        total += [section count];
    }];

    return total;
}

- (NSUInteger)numberOfSections
{
    return self.sections.count;
}

- (NSArray *)sectionAtIndex:(NSUInteger)sectionIndex
{
    return [self.sections objectAtIndex:sectionIndex];
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    NSArray *section = [self.sections objectAtIndex:sectionIndex];
    return [section count];
}

- (id)itemForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section >= (NSInteger) self.sections.count) {
        return nil;
    }
    
    NSArray *section = [self.sections objectAtIndex:indexPath.section];

    if (indexPath.item >= (NSInteger)section.count) {
        return nil;
    }
    
    return [section objectAtIndex:indexPath.item];
}

- (NSIndexPath *)indexPathForItem:(id<NSObject>)objectSearch
{
    if (objectSearch == nil) {
        return nil;
    }
    NSIndexPath *__block result = nil;
    [self enumerateItems:^(NSArray *section, NSUInteger sectionIndex, id<NSObject> item, NSUInteger itemIndex, BOOL *stop) {
        if ([item isEqual:objectSearch]) {
            result = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            *stop = YES;
        }
    }];

    return result;
}

- (NSIndexPath *)convertLocalIndexPath:(NSIndexPath *)local fromSection:(NSUInteger)sectionIndex
{
    return [NSIndexPath indexPathForItem:local.item inSection:sectionIndex];
}

@end
