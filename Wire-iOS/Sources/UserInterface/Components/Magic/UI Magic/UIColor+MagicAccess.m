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


#import "UIColor+MagicAccess.h"
#import "WAZUIMagic.h"



@implementation UIColor (MagicAccess)

+ (instancetype)colorWithMagicIdentifier:(NSString *)identifier
{
    WAZUIMagic *magic = [WAZUIMagic sharedMagic];

    NSArray *c = magic[identifier];
    CGFloat accentComponents[4], colorResult[4] = {0, 0, 0, 0};
    UIColor *accentColor = nil;

    NSArray *stuff = @[
            @[@(0), @"accent_red"],
            @[@(1), @"accent_green"],
            @[@(2), @"accent_blue"],
            @[@(3), @"accent_alpha"]];

    for (NSArray *color in stuff) {
        NSInteger ndx = [color[0] integerValue];
        if ([c[ndx] isKindOfClass:[NSString class]] &&
                [c[ndx] isEqualToString:color[1]]) {
            if (! accentColor) {
                accentColor = [WAZUIMagic accentColor];
                [accentColor getRed:&(accentComponents[0])
                              green:&(accentComponents[1])
                               blue:&(accentComponents[2])
                              alpha:&(accentComponents[3])];
            }
            colorResult[ndx] = accentComponents[ndx];
        }
        else {
            colorResult[ndx] = [c[ndx] floatValue];
        }
    }

    return [UIColor colorWithRed:colorResult[0]
                           green:colorResult[1]
                            blue:colorResult[2]
                           alpha:colorResult[3]];
}

+ (NSArray *)colorArrayWithMagicIdentifier:(NSString *)identifier
{
    NSArray *colorArrays = [[WAZUIMagic sharedMagic] valueForKeyPath:identifier];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:colorArrays.count];

    for (NSArray *colorArray in colorArrays) {
        UIColor *color = [UIColor colorWithArray:colorArray];
        [result addObject:color];
    }

    return [NSArray arrayWithArray:result];
}

+ (instancetype)colorWithArray:(NSArray *)array
{
    NSAssert([array isKindOfClass:[NSArray class]], @"Color components must be an array");
    NSAssert(3 <= [array count], @"Not enough color components");

    float alpha = (3 < array.count) ? [array[3] floatValue] : 1;
    return [UIColor colorWithRed:[array[0] floatValue]
                           green:[array[1] floatValue]
                            blue:[array[2] floatValue]
                           alpha:alpha];
}

+ (NSArray *)allProfileColors
{
    NSArray *accentColors = [WAZUIMagic sharedMagic][@"accent_colors"];
    NSMutableArray __block *mapped = [NSMutableArray arrayWithCapacity:accentColors.count];
    
    [accentColors enumerateObjectsUsingBlock:^(NSArray *components, NSUInteger idx, BOOL *stop) {
        [mapped addObject:[UIColor colorWithRed:[components[0] floatValue]
                                          green:[components[1] floatValue]
                                           blue:[components[2] floatValue]
                                          alpha:[components[3] floatValue]
                           ]];
    }];
    
    return mapped;
}

@end
