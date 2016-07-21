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


#import "IdentifiableColor.h"



@interface IdentifiableColor ()

@property (nonatomic, strong, readwrite) UIColor *color;
@property (nonatomic, assign, readwrite) NSUInteger tag;

@end

@implementation IdentifiableColor

- (instancetype)initWithColor:(UIColor *)color tag:(NSUInteger)tag
{
    self = [super init];
    if (self) {
        self.color = color;
        self.tag = tag;
    }
    return self;
}

@end



@implementation NSArray (IdentifiableColor)

- (IdentifiableColor *)wr_identifiableColorByColor:(UIColor *)color
{
    __block IdentifiableColor *found = nil;
    [self enumerateObjectsUsingBlock:^(IdentifiableColor *identifiableColor, NSUInteger idx, BOOL *stop) {
        if (identifiableColor.color == color) {
            found = identifiableColor;
        }
    }];
    return found;
}

- (IdentifiableColor *)wr_identifiableColorByTag:(NSUInteger)tag
{
    __block IdentifiableColor *found = nil;
    [self enumerateObjectsUsingBlock:^(IdentifiableColor *identifiableColor, NSUInteger idx, BOOL *stop) {
        if (identifiableColor.tag == tag) {
            found = identifiableColor;
        }
    }];
    return found;
}

@end
