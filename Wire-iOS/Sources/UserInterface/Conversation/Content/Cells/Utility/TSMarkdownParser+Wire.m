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


#import "TSMarkdownParser+Wire.h"

#import "WAZUIMagicIOS.h"



@implementation TSMarkdownParser (Wire)

+ (instancetype)standardWireParserWithTextColor:(UIColor *)textColor
{
    TSMarkdownParser *defaultParser = [TSMarkdownParser new];
    
    UIFont *contentFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    UIFont *monoFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_mono"];
    UIColor *monoColor = textColor;

    defaultParser.paragraphFont = contentFont;
    defaultParser.strongFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_bold"];
    defaultParser.emphasisFont = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_italic"];
    defaultParser.h1Font = [UIFont fontWithMagicIdentifier:@"style.text.header1.font_spec"];
    defaultParser.monospaceFont = monoFont;
    defaultParser.monospaceTextColor = monoColor;
    NSDictionary *bulletPointAttributes = @{NSFontAttributeName: contentFont, NSForegroundColorAttributeName: [UIColor colorWithMagicIdentifier:@"style.color.markdown.bullet_point_color"]};
    NSAttributedString *attributedBulletPointString = [[NSAttributedString alloc] initWithString:@"• " attributes:bulletPointAttributes];

    
    __weak TSMarkdownParser *weakParser = defaultParser;
    [defaultParser addParagraphParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.paragraphFont
                                 range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:textColor
                                 range:range];
    }];
    
    // Bold
    [defaultParser addStrongParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.strongFont
                                 range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:textColor
                                 range:range];
    }];
    
    // Emphasis
    [defaultParser addEmphasisParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.emphasisFont
                                 range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:textColor
                                 range:range];
    }];
    
    // Mono
    [defaultParser addMonospacedParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.monospaceFont
                                 range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:weakParser.monospaceTextColor
                                 range:range];
    }];
    
    // List parsing
    [defaultParser addListParsingWithFormattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString replaceCharactersInRange:range withAttributedString:attributedBulletPointString];
    }];
   
    // h1
    [defaultParser addHeaderParsingWithLevel:1 formattingBlock:^(NSMutableAttributedString *attributedString, NSRange range) {
        [attributedString addAttribute:NSFontAttributeName
                                 value:weakParser.h1Font
                                 range:range];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:textColor
                                 range:range];
    }];
    
    return defaultParser;
}

@end
