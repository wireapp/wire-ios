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


#import "CachingFrameAnimationView.h"

@interface FrameAnimationView ()
@property (nonatomic, assign) CGImageRef image;
@property (nonatomic, assign) CGImageRef tintedImage;
- (void)applyTintColor;
@end

@interface UIColor (StringRepresentation)
- (NSString *)RGBAString;
@end

@implementation UIColor (StringRepresentation)

- (NSString *)RGBAString
{
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        return [NSString stringWithFormat:@"%.02f, %.02f, %.02f, %.02f", r, g, b, a];
    }
    else {
        return nil;
    }
}

@end

@interface CachingFrameAnimationView ()
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, assign) BOOL pendingApplyTint;
@end


@implementation CachingFrameAnimationView

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];

    if (!hidden && self.pendingApplyTint) {
        [self applyTintColor];
    }
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];

    if (alpha != 0 && self.pendingApplyTint) {
        [self applyTintColor];
    }
}

- (void)applyTintColor
{
    if (self.tintColor == nil || self.image == nil) {
        self.tintedImage = self.image;
        return;
    }

    if (self.hidden || self.alpha == 0) {
        self.pendingApplyTint = YES;
        return;
    }
    else {
        self.pendingApplyTint = NO;
    }

    if (self.imageCache == nil) {
        self.imageCache = NSCache.new;
    }

    CGImageRef cachedImage = (__bridge CGImageRef)[self.imageCache objectForKey:self.tintColor.RGBAString];
    if (cachedImage != nil) {
        self.tintedImage = cachedImage;
    }
    else {
        [super applyTintColor];
        [self.imageCache setObject:(__bridge id)self.tintedImage forKey:self.tintColor.RGBAString];
    }
}

@end
