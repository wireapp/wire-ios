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


#import "NSAttributedString+Wire.h"



@implementation  NSString (WireAttributedString)

- (NSAttributedString *)attributedStringWithAttributes:(NSDictionary *)attributes;
{
    if (attributes == nil) {
        return [[NSAttributedString alloc] initWithString:self];
    }
    
    return [[NSAttributedString alloc] initWithString:self attributes:attributes];
}

@end



@implementation NSAttributedString (Wire)

+ (instancetype)attributedStringWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    va_list args;
    va_start(args, format);
    id result = [self attributedStringWithDefaultAttributes:@{} format:format arguments:args];
    va_end(args);
    return result;
}

+ (instancetype)attributedStringWithDefaultAttributes:(NSDictionary *)attributes format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3)
{
    va_list args;
    va_start(args, format);
    id result = [self attributedStringWithDefaultAttributes:attributes format:format arguments:args];
    va_end(args);
    return result;
}

+ (instancetype)attributedStringWithDefaultAttributes:(NSDictionary *)defaultAttributes format:(NSString *)format arguments:(va_list)args
{
    NSMutableArray *arguments = [[self argumentsFromVAArgs:args
                                                     count:[self numberOfSubstitutionPointsInFormat:format]]
                                 mutableCopy];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:format];
    
    [attributedString beginEditing];
    [attributedString setAttributes:defaultAttributes range:NSMakeRange(0, attributedString.length)];
    
    NSRange range = [format rangeOfString:@"%@" options:NSBackwardsSearch];
    for (NSUInteger index = 0; range.location != NSNotFound; index++) {
        id argument = [arguments lastObject];
        [arguments removeLastObject];
        
        if ([argument isKindOfClass:[NSAttributedString class]]) {
            [attributedString replaceCharactersInRange:range withAttributedString:argument];
        } else {
            [attributedString replaceCharactersInRange:range withString:[argument description]];
        }
        
        range = NSMakeRange(0, range.location);
        range = [format rangeOfString:@"%@" options:NSBackwardsSearch range:range];
    }
    [attributedString endEditing];
    
    return [[self alloc] initWithAttributedString:attributedString];
}

+ (NSUInteger)numberOfSubstitutionPointsInFormat:(NSString *)format
{
    NSError *error = nil;
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:@"%@"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&error];
    if (error == nil) {
        return [regExp numberOfMatchesInString:format options:0 range:NSMakeRange(0, format.length)];
    } else {
        return 0;
    }
}

+ (NSArray *)argumentsFromVAArgs:(va_list)args count:(NSUInteger)count
{
    NSMutableArray *arguments = [NSMutableArray new];
    for (NSUInteger index = 0; index < count; index++) {
        id argument = va_arg(args, id);
        [arguments addObject:argument];
    }
    return arguments;
}

@end



@implementation NSMutableAttributedString (Wire)

- (void)appendString:(NSString *)string attributes:(NSDictionary *)attributes;
{
    NSAttributedString *attrString = [string attributedStringWithAttributes:attributes];
    if (attrString != nil) {
        [self appendAttributedString:attrString];
    }
}

@end
