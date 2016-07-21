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



#import <Foundation/Foundation.h>



@interface UIFont (MagicAccess)

/// Parses the declaration in style like '{ font : "System-Medium", size: 27.0 }'. Also considers advanced typography properties (number_spacing: proportional/monospace. This should be the primary mechanism for defining fonts going forward, as it contains the best support for advanced typographic features.
/// @return Will return nil in case its cant find the definition
+ (UIFont *)fontWithMagicIdentifier:(NSString *)identifier;

/// @return Will return nil in case its cant find the definition
+ (UIFont *)fontWithMagicIdentifierFontNameKey:(NSString *)fontName fontSizeKey:(NSString *)fontSize DEPRECATED_ATTRIBUTE;

/// Will use the prefix path append the _font and _size to it, use this two keys to find the font name and the font size in the magic and combine those to UIFont object. In case it doesn't word nil will be returned
+ (UIFont *)fontWithMagicIdentifierPrefixPath:(NSString *)path DEPRECATED_ATTRIBUTE;

@end
