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


#import <UIKit/UIKit.h>



@interface BackgroundView : UIView

@property (nonatomic, readonly) CGFloat defaultHorizontalParallaxInset;
@property (nonatomic, readonly) CGFloat defaultVerticalParallaxInset;
@property (nonatomic, assign) CGPoint parallaxOffset;

@property (nonatomic, strong) UIColor *filterColor;

/// Set whether the filters are enabled (vignette, darkening).  Animates.
@property (nonatomic, assign) BOOL filterDisabled;

/// Set whether the blur is enabled.  Animates.
@property (nonatomic, assign) BOOL blurDisabled;

/// Set the percent visibility of the blur overlay.  Doesn't animate.
@property (nonatomic, assign) CGFloat blurPercent;
/// Indicates whether the view will wait until a blur is generated before changing images
@property (nonatomic, readonly) BOOL waitForBlur;


- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithFilterColor:(UIColor *)filterColor NS_DESIGNATED_INITIALIZER;

/// Set the main "image" to be a flat color.  Overrides whatever the current image is.
- (void)setFlatColor:(UIColor *)color;

- (void)setImageData:(NSData *)imageData withCacheKey:(NSString *)cacheKey
            animated:(BOOL)animated;

- (void)setImageData:(NSData *)imageData withCacheKey:(NSString *)cacheKey
            animated:(BOOL)animated waitForBlur:(BOOL)waitForBlur;

- (void)setImageData:(NSData *)imageData withCacheKey:(NSString *)cacheKey
            animated:(BOOL)animated waitForBlur:(BOOL)waitForBlur
         forceUpdate:(BOOL)forceUpdate;

- (void)setBlurPercentAnimated:(CGFloat)blurPercent;

@end


@interface BackgroundView (Animations)

- (void)updateAppearanceAnimated:(BOOL)animated;

@end
