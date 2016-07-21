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


@import UIKit;
#import "NSString+TextTransform.h"



@class Token;
@class TokenField;
@class TextView;
@class IconButton;


@protocol TokenFieldDelegate <NSObject>

@optional
- (void)tokenField:(TokenField *)tokenField changedTokensTo:(NSArray *)tokens;
- (void)tokenField:(TokenField *)tokenField changedFilterTextTo:(NSString *)text;
- (void)tokenFieldDidBeginEditing:(TokenField *)tokenField;
- (void)tokenFieldWillScroll:(TokenField *)tokenField;
- (void)tokenFieldDidConfirmSelection:(TokenField *)controller;
- (NSString *)tokenFieldStringForCollapsedState:(TokenField *)tokenField;

@end


IB_DESIGNABLE
@interface TokenField : UIView

@property (weak, nonatomic) IBOutlet id<TokenFieldDelegate> delegate;

@property (strong, readonly, nonatomic) TextView *textView;

@property (assign, nonatomic) BOOL hasAccessoryButton;
@property (strong, readonly, nonatomic) IconButton *accessoryButton;

@property (strong, readonly, nonatomic) NSArray *tokens;
@property (copy, readonly, nonatomic) NSString *filterText;

- (void)addToken:(Token *)token;
- (void)addTokenForTitle:(NSString *)title representedObject:(id)object;
- (Token *)tokenForRepresentedObject:(id)object;    // searches by isEqual:
- (void)removeToken:(Token *)token;
- (void)removeAllTokens;
- (void)clearFilterText;

// Collapse

@property (assign, nonatomic) NSUInteger numberOfLines; // in not collapsed state; in collapsed state - 1 line; default to NSUIntegerMax
@property (assign, nonatomic, getter=isCollapsed) BOOL collapsed;
- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated;


// Appearance

@property (strong, nonatomic) IBInspectable NSString *toLabelText;

@property (strong, nonatomic) IBInspectable UIFont *font;
@property (strong, nonatomic) IBInspectable UIColor *textColor;

@property (strong, nonatomic) IBInspectable UIFont *tokenTitleFont;
@property (strong, nonatomic) IBInspectable UIColor *tokenTitleColor;
@property (strong, nonatomic) IBInspectable UIColor *tokenSelectedTitleColor;
@property (strong, nonatomic) IBInspectable UIColor *tokenBackgroundColor;
@property (strong, nonatomic) IBInspectable UIColor *tokenSelectedBackgroundColor;
@property (strong, nonatomic) IBInspectable UIColor *tokenBorderColor;
@property (strong, nonatomic) IBInspectable UIColor *tokenSelectedBorderColor;
@property (assign, nonatomic) TextTransform tokenTextTransform;

@property (assign, nonatomic) IBInspectable CGFloat lineSpacing;
@property (assign, nonatomic) IBInspectable CGFloat tokenOffset;    // horisontal distance between tokens, and btw "To:" and first token
@property (assign, nonatomic) IBInspectable CGFloat tokenHeight;    // if set to 0.0 or bigger than tokenField.font.leading, tokenField.font.leading value is used
@property (assign, nonatomic) IBInspectable CGFloat tokenTitleVerticalAdjustment;

// Utils
@property (assign, nonatomic) CGRect excludedRect;  // rect for excluded path in textView text container

@property (assign, nonatomic, readonly) BOOL userDidConfirmInput;
- (void)filterUnwantedAttachments;

- (void)scrollToBottomOfInputField;

- (BOOL)isFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;


@end
