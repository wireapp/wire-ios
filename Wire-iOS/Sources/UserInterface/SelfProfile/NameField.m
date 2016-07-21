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



#import "NameField.h"
#import "WAZUIMagicIOS.h"
#import "ResizingTextView.h"
#import "UIView+Borders.h"
#import "UIImage+ZetaIconsNeue.h"
@import WireExtensionComponents;

NSUInteger const NameFieldUserMaxLength = 64;

@interface NameField ()

@property (nonatomic, strong, readwrite) ResizingTextView *textView;
@property (nonatomic, strong) UIView *guidanceDot;

@property (nonatomic) BOOL hintPresented;
@property (nonatomic, copy) NSString *magicKeypath;

@end



@implementation NameField

+ (instancetype)nameField
{
    NameField *nameField = [[NameField alloc] init];
    return nameField;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        self.hintPresented = NO;
        
        [self setupTextView];
        [self setupGuidanceDot];
        [self setupConstraints];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:self.textView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myEndEditing:) name:UITextViewTextDidEndEditingNotification object:self.textView];
    }
    
    return self;
}

- (void)dealloc
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupTextView
{
    self.textView = [[ResizingTextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.textView];
    
    self.textView.backgroundColor = [UIColor clearColor];
}

- (void)setupGuidanceDot
{
    CGFloat dotSize = [WAZUIMagic cgFloatForIdentifier:@"guidance.dot_size"];
    UIColor *dotColor = [UIColor colorWithMagicIdentifier:@"guidance.guidance_type_required_color"];
    
    self.guidanceDot = [[UIView alloc] init];
    self.guidanceDot.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.guidanceDot];
    
    self.guidanceDot.layer.cornerRadius = dotSize / 2.0f;
    self.guidanceDot.layer.backgroundColor = dotColor.CGColor;
    
    [self.guidanceDot addConstraintForWidth:dotSize];
    [self.guidanceDot addConstraintForHeight:dotSize];
    
    self.guidanceDot.hidden = YES;
}

- (void)setupConstraints
{
    [self.textView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.textView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    [self.textView addConstraintForTopMargin:0.0 relativeToView:self];
    [self.textView addConstraintForBottomMargin:0.0f relativeToView:self];
    [self.textView addConstraintForLeftMargin:0.0 relativeToView:self];
    [self.textView addConstraintForRightMargin:0.0 relativeToView:self];
    
    CGFloat guidanceDotTopMargin = 15;
    [self.guidanceDot addConstraintForTopMargin:guidanceDotTopMargin relativeToView:self];
    [self.guidanceDot addConstraintForRightMargin:24 relativeToView:self];
}

- (void)setShowGuidanceDot:(BOOL)showGuidanceDot
{
    self.guidanceDot.hidden = ! showGuidanceDot;
}

- (void)configureWithMagicKeypath:(NSString *)keypath
{
    self.magicKeypath = keypath;
    NSDictionary *dict = [self magicDictionary];
    self.layer.cornerRadius = [dict[@"corner_radius"] floatValue];
    self.layer.masksToBounds = YES;
    
    self.textView.textContainerInset = UIEdgeInsetsMake([dict[@"padding_top"] floatValue],
                                                        [dict[@"padding_left"] floatValue],
                                                        [dict[@"padding_bottom"] floatValue],
                                                        [dict[@"padding_right"] floatValue]);
    
    if (! self.shouldHighlightOnFocus) {
        self.backgroundColor = [UIColor colorWithMagicIdentifier:[self.magicKeypath stringByAppendingString:@".background_color"]];
    }
}

#pragma mark - Hint

- (void)showEditingHint
{
    if (self.hintPresented || ! self.shouldPresentHint) {
        return;
    }
    
    self.hintPresented = YES;
    
    NSDictionary *dict = [self magicDictionary];
    if ( ! dict) {
        return;
    }
    
    if ( ! [self.textView.text hasSuffix:[self editingHint].string]) {
        [self.textView.textStorage appendAttributedString:[self editingHint]];
        
        @weakify(self);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([dict[@"hint_dismiss_delay"] floatValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self)
            [self dismissEditingHint];
        });
    }
}

- (void)dismissEditingHint
{
    if (self.shouldPresentHint && [self.textView.text hasSuffix:[self editingHint].string]) {
        [self.textView.textStorage replaceCharactersInRange:[self.textView.textStorage.string rangeOfString:[self editingHint].string] withString:@""];
    }
}

- (NSAttributedString *)editingHint
{
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    textAttachment.image = [UIImage imageForIcon:ZetaIconTypePencil iconSize:ZetaIconSizeTiny color:self.textView.textColor];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@" "];
    [string appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
    return [string copy];
}

- (NSDictionary *)magicDictionary
{
    if (! self.magicKeypath) {
        return nil;
    }
    
    return [WAZUIMagic sharedMagic][self.magicKeypath];
}


#pragma mark - Notification listeners

- (void)myBeginEditing:(NSNotification *)note
{
    [self dismissEditingHint];
    
    if (!self.magicKeypath) {
        return;
    }
    
    if (self.shouldHighlightOnFocus) {
    
        [UIView animateWithAnimationIdentifier:[self.magicKeypath stringByAppendingString:@".focused_background_show_animation"] animations:^{
            self.backgroundColor = [UIColor colorWithMagicIdentifier:[self.magicKeypath stringByAppendingString:@".background_color_focused"]];
        } options:0 completion:nil];
    }
}

- (void)myEndEditing:(NSNotification *)note
{
    if (!self.magicKeypath) {
        return;
    }
    
    if (self.shouldHighlightOnFocus) {
        
        [UIView animateWithAnimationIdentifier:[self.magicKeypath stringByAppendingString:@".focused_background_hide_animation"] animations:^{
            self.backgroundColor = [UIColor colorWithMagicIdentifier:[self.magicKeypath stringByAppendingString:@".background_color"]];
        } options:0 completion:nil];
    }
}

- (BOOL)makeTextViewFirstResponder
{
    return [self.textView becomeFirstResponder];
}


@end


