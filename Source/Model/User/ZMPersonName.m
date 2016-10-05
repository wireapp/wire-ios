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


#import "NSString+ZMPersonName.h"
#import "ZMPersonName.h"



typedef NS_ENUM(NSUInteger, ZMPersonNameOrder) {
    ZMPersonNameOrderGivenNameFirst,
    ZMPersonNameOrderGivenNameLast,
    ZMPersonNameOrderArabicGivenNameFirst,
};

@interface ZMPersonName ()
@property (nonatomic, copy) NSArray *components;
@property (nonatomic, copy) NSArray *secondNameComponents;

@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, copy) NSString *givenName;
@property (nonatomic, copy) NSString *abbreviatedName;
@property (nonatomic, copy) NSString *initials;

@property (nonatomic) ZMPersonNameOrder nameOrder;
@end

@implementation ZMPersonName

+ (instancetype)personWithName:(NSString *)name
{
    static NSCache *stringsToPersonNames = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stringsToPersonNames = [NSCache new];
    });
    
    ZMPersonName *cachedPersonName = [stringsToPersonNames objectForKey:name];
    
    if (cachedPersonName != nil) {
        return cachedPersonName;
    }
    else {
        cachedPersonName = [[ZMPersonName alloc] initWithName:name];
        [stringsToPersonNames setObject:cachedPersonName forKey:name];
        return cachedPersonName;
    }
}

- (instancetype)initWithName:(NSString *)name;
{
    self = [super init];
    
    if (self) {
        // We're using -precomposedStringWithCanonicalMapping (Unicode Normalization Form C)
        // since this allows us to use faster string comparison later.
        self.fullName = [name precomposedStringWithCanonicalMapping];
        self.nameOrder = [self scriptOfString:name];
        self.components = [self splitNameComponents];
    }
    return self;
}

- (ZMPersonNameOrder)scriptOfString:(NSString *)string;
{
    // We are checking the linguistic scheme in order to distinguisch between differences in the order of given and last name
    // If the name contains latin scheme tag, it uses the first name as the given name
    // If the name is in arab sript, we will check if the givenName consists of "servent of" + one of the names for god
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:@[NSLinguisticTagSchemeScript] options:0];
    tagger.string = string;
    NSArray *tags = [tagger tagsInRange:NSMakeRange(0, tagger.string.length) scheme:NSLinguisticTagSchemeScript options:NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitOther | NSLinguisticTaggerJoinNames tokenRanges:nil];
    
    ZMPersonNameOrder nameOrder;
    
    if ([tags containsObject:@"Arab"])
    {
        nameOrder = ZMPersonNameOrderArabicGivenNameFirst;
    }
    else if ([tags containsObject:@"Hani"] ||
             [tags containsObject:@"Jpan"] ||
             [tags containsObject:@"Deva"] ||
             [tags containsObject:@"Gurj"])
    {
        if ([tags containsObject:@"Latn"]) {
            nameOrder = ZMPersonNameOrderGivenNameFirst;

        }
        else {
            nameOrder = ZMPersonNameOrderGivenNameLast;
        }
    }
    else 
    {
        nameOrder = ZMPersonNameOrderGivenNameFirst;
    }
    
    return nameOrder;
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    for (NSString *s in self.components) {
        hash ^= s.hash;
    }
    return hash;
}

- (BOOL)isEqual:(id)object;
{
    if (! [object isKindOfClass:[ZMPersonName class]]) {
        return NO;
    }
    
    ZMPersonName *other = object;
    return [other.components isEqual:self.components];
}

- (NSArray *)splitNameComponents
{
    NSRange const fullRange = NSMakeRange(0, self.fullName.length);
    NSMutableArray *components = [NSMutableArray array];
    __block NSString *component;
    __block NSRange lastRange = {NSNotFound, 0};

    // This is a bit more complicated because we don't want chinese names to be split up by their individual characters
    NSLinguisticTaggerOptions const options = (NSLinguisticTaggerOmitPunctuation |
                                               NSLinguisticTaggerOmitWhitespace |
                                               NSLinguisticTaggerOmitOther);
    [self.fullName enumerateLinguisticTagsInRange:fullRange scheme:NSLinguisticTagSchemeTokenType options:options orthography:nil usingBlock:^(NSString *tag, NSRange substringRange, NSRange __unused sentenceRange, BOOL * __unused stop) {
        if (! [tag isEqualToString:NSLinguisticTagWord]) {
            return;
        }
        NSString *substring = [self.fullName substringWithRange:substringRange];
        if (component != nil) {
            if (NSMaxRange(lastRange) == substringRange.location) {
                component = [component stringByAppendingString:substring];
                return;
            }
            [components addObject:component];
            component = nil;
        }
        if (substring.length != 0) {
            component = substring;
            lastRange = substringRange;
        } else {
            lastRange = NSMakeRange(NSNotFound, 0);
        }
    }];
    if (component != nil) {
        [components addObject:component];
    }
    return components;
}

- (NSString *)givenName
{
    if (_givenName == nil) {
        if (self.components.count == 0) {
            _givenName = self.fullName;
        } else {
            NSMutableString *givenName = [NSMutableString string];
            switch (self.nameOrder) {
                case ZMPersonNameOrderGivenNameLast:
                    [givenName appendString:self.components.lastObject];
                    break;
                case ZMPersonNameOrderGivenNameFirst:
                    [givenName appendString:self.components.firstObject];
                    break;
                    
                case ZMPersonNameOrderArabicGivenNameFirst:
                    [givenName appendString:self.components.firstObject];
                    if (self.components.count > 1 && [self.components[1] zmIsGodName]) {
                        [givenName appendString:@" "];
                        [givenName appendString:self.components[1]];
                    }
                    break;
            }
            _givenName = [givenName copy];
        }
        _givenName = _givenName ?: @"";
    }
    return _givenName;
}

- (NSArray *)secondNameComponents
{
    if (self.components.count <2) return nil;
    
    NSUInteger startIndex;
    NSUInteger length;
    
    switch (self.nameOrder) {
        case ZMPersonNameOrderGivenNameLast:
            startIndex = 0;
            length = self.components.count-2;
            break;
            
        case ZMPersonNameOrderGivenNameFirst:
            startIndex = 1;
            length = self.components.count-1;
            break;
            
        case ZMPersonNameOrderArabicGivenNameFirst:
            startIndex = 1;
            length = self.components.count-1;
            if ([self.components[1] zmIsGodName]) {
                if (self.components.count > 2) {
                    startIndex++;
                    length--;
                }
                else {
                    return nil;
                }
            }
            break;
    }

    return [self.components subarrayWithRange:NSMakeRange(startIndex, length)];
}


- (NSString *)abbreviatedName
{
    if (_abbreviatedName == nil) {
        if (!self.secondNameComponents) {
            _abbreviatedName = self.givenName;
        }
        else {
            NSString *abbreviatedSecondName = [self.components.lastObject zmLeadingNumberOrFirstComposedCharacter];
            _abbreviatedName = [NSString stringWithFormat:@"%@ %@", self.givenName, abbreviatedSecondName];
        }
    }
    return _abbreviatedName;
}

- (NSString *)initials
{
    if (_initials == nil) {
        if (self.components.count == 0) {
            _initials = @"";
        }
        else {
            NSMutableString *initials = [NSMutableString string];
            
            switch (self.nameOrder) {
                case ZMPersonNameOrderGivenNameLast:
                    [initials appendString:[self.components.firstObject zmFirstComposedCharacter] ?: @""];
                    [initials appendString:[self.components.firstObject zmSecondComposedCharacter] ?: @""];
                    break;
                case ZMPersonNameOrderArabicGivenNameFirst:
                case ZMPersonNameOrderGivenNameFirst:
                    [initials appendString:[self.components.firstObject zmFirstComposedCharacter] ?: @""];
                    if (self.components.count >1) {
                        [initials appendString:[self.components.lastObject zmFirstComposedCharacter] ?: @""];
                    }
                    break;
            }
            _initials = [initials copy] ?: @"";
        }
    }
    return _initials;
}

# pragma mark - Helpers

- (BOOL)stringStartsWithUppercaseString:(NSString *)string
{
    NSCharacterSet *uppercaseCharacterSet = [NSCharacterSet uppercaseLetterCharacterSet];
    return [uppercaseCharacterSet characterIsMember:[string characterAtIndex:0]];
}

@end
