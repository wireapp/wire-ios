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


#import "TextViewWithDataDetectorWorkaround.h"



@interface MyTextStorage : NSTextStorage
@end



@interface TextViewWithDataDetectorWorkaround () <UITextViewDelegate>
@end



@implementation TextViewWithDataDetectorWorkaround

- (id)initWithFrame:(CGRect)frame
{
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(10, 10)];

    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];

    MyTextStorage *textStorage = [[MyTextStorage alloc] init];
    [textStorage addLayoutManager:layoutManager];

    self = [super initWithFrame:frame textContainer:textContainer];

    self.delegate = self;

    return self;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
 
    // if long press, we should should not open link, but rather select the link
    for (UIGestureRecognizer *gestureRecognizer in textView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            UILongPressGestureRecognizer *longPressGesture = (UILongPressGestureRecognizer *)gestureRecognizer;
            if (longPressGesture.state == UIGestureRecognizerStateBegan) {
                if ([self.textViewInteractionDelegate respondsToSelector:@selector(textView:didLongPressLinkWithGestureRecognizer:)]) {
                    [self.textViewInteractionDelegate textView:self didLongPressLinkWithGestureRecognizer:longPressGesture];
                }
                return NO;
            }
        }
    }
    
    if ([self.textViewInteractionDelegate respondsToSelector:@selector(textView:willOpenURL:)]) {
        [self.textViewInteractionDelegate textView:self willOpenURL:URL];
    }
    
    return YES;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL isInside = [super pointInside:point withEvent:event];

    if (! isInside) {
        return NO;
    }

    UITextRange *textPosition = [self characterRangeAtPoint:point];
    NSUInteger index = [self offsetFromPosition:self.beginningOfDocument toPosition:textPosition.start];
    
    return [self URLAttributeAtIndex:index];
}

- (BOOL)URLAttributeAtIndex:(NSUInteger)index
{
	if (self.attributedText.length == 0) {
		return NO;
	}
    NSDictionary *attributes = [self.attributedText attributesAtIndex:index effectiveRange:NULL];
    return [attributes valueForKey:NSLinkAttributeName] != nil;
}

@end



@implementation MyTextStorage
{
    NSMutableAttributedString *textStorage;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        textStorage = [[NSMutableAttributedString alloc] init];
    }
    return self;
}

- (NSString *)string
{
    return [textStorage string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange
{
    // Index checking, return nil if the index is out of bound
    if (index >= self.length) {
        return @{};
    }
    NSDictionary *attributes = [textStorage attributesAtIndex:index effectiveRange:aRange];
    return attributes;
}

- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString
{
    [textStorage replaceCharactersInRange:aRange withString:aString];
    [self edited:NSTextStorageEditedCharacters range:aRange changeInLength:[aString length] - aRange.length];
}

- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
    [textStorage setAttributes:attributes range:aRange];
    [self edited:NSTextStorageEditedAttributes range:aRange changeInLength:0];
}

@end

