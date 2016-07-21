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


#import "BackgroundView.h"
#import "BackgroundViewImageProcessor.h"
#import "WAZUIMagic.h"
#import "UIColor+MagicAccess.h"
#import "UIImage+ImageUtilities.h"

#import "Constants.h"
#import "UIView+MTAnimation.h"
#import "UIView+Borders.h"
#import "UIColor+WR_ColorScheme.h"
#import <PureLayout/PureLayout.h>


@interface BackgroundView (AnimationsInternal)

- (void)updateBlurAnimated:(BOOL)animated;

@end




@interface BackgroundView ()

@property (nonatomic, strong) BackgroundViewImageProcessor *imageProcessor;

@property (nonatomic, strong) UIView *containerView;

// We crossfade between these two image views to approximate interactive blur
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *blurImageView;

@property (nonatomic, strong) UIView *overlayContainer;
@property (nonatomic, strong) UIView *colorOverlay;
@property (nonatomic, strong) UIView *darkOverlay;
@property (nonatomic, strong) UIImageView *vignetteOverlay;

@property (nonatomic, strong) UIImage *vignetteImage;
/// Vignette to use when there is no user image
@property (nonatomic, strong) UIImage *vignetteImageNoPicture;

@property (nonatomic, assign) BOOL isShowingFlatColor;
@property (nonatomic, strong) UIColor *flatColor;

@property (nonatomic, strong) CIContext *ciContext;

@property (nonatomic, assign) BOOL waitForBlur;

@property (nonatomic, strong) NSString *originalImagePendingCacheID;
@property (nonatomic, strong) NSString *originalImageCacheID;
@property (nonatomic, strong) NSString *blurredImagePendingCacheID;
@property (nonatomic, strong) NSString *blurredImageCacheID;

@property (strong, nonatomic) UIImage *blurredImage;
@property (strong, nonatomic) UIImage *originalImage;

@property (nonatomic, strong) NSOperationQueue *imageProcessingQueue;

// Magic values
@property (nonatomic, assign) NSTimeInterval animationDuration;

@end



@implementation BackgroundView

- (instancetype)initWithFilterColor:(UIColor *)filterColor
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _filterColor = filterColor;
        _filterDisabled = NO;
        _blurPercent = 0;
        _blurDisabled = NO;
        [self setupBackgroundView];
    }
    
    return self;
}

- (void)setupBackgroundView
{
    self.clipsToBounds = YES;
    self.imageProcessor = [[BackgroundViewImageProcessor alloc] init];
    
    [self updateMagicValues];
    
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.containerView];
    
    [UIView performWithoutAnimation:^{
        [self createImageView];
        [self createOverlays];
    }];
    
    [self createInitialConstraints];
    [self updateOverlayAppearanceWithVisibleImage:NO];
}

- (void)updateMagicValues
{
    // Grab the motion effect metrics
    self.animationDuration = [WAZUIMagic floatForIdentifier:@"background.animation_duration"];
}

- (void)createImageView
{
    // Create a user image view
    self.imageView = [[UIImageView alloc] initWithFrame:self.containerView.bounds];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.imageView];
    
    self.imageView.clipsToBounds = YES;
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = NO;
    
    // Create a user image view
    self.blurImageView = [[UIImageView alloc] initWithFrame:self.containerView.bounds];
    self.blurImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.blurImageView];
    
    self.blurImageView.clipsToBounds = YES;
    self.blurImageView.backgroundColor = [UIColor clearColor];
    self.blurImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.blurImageView.clipsToBounds = NO;
}

- (void)createOverlays
{
    self.overlayContainer = [[UIView alloc] init];
    self.overlayContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.overlayContainer];
    
    self.darkOverlay = [[UIView alloc] init];
    self.darkOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.darkOverlay.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorBackgroundOverlay];
    [self.overlayContainer addSubview:self.darkOverlay];
    
    self.colorOverlay = [[UIView alloc] init];
    self.colorOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.colorOverlay.backgroundColor = self.filterColor;
    self.colorOverlay.alpha = [WAZUIMagic floatForIdentifier:@"background.color_overlay_opacity"];
    [self.overlayContainer addSubview:self.colorOverlay];
    
    self.vignetteOverlay = [[UIImageView alloc] init];
    self.vignetteOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.vignetteOverlay.backgroundColor = [UIColor clearColor];
    self.vignetteOverlay.layer.masksToBounds = YES;
    self.vignetteOverlay.contentMode = UIViewContentModeScaleToFill;
    [self.overlayContainer addSubview:self.vignetteOverlay];
}

- (CGSize)vignetteSize
{
    CGRect windowBounds = [UIApplication sharedApplication].keyWindow.bounds;
    CGFloat maxOverlayDimension = MAX(windowBounds.size.width, windowBounds.size.height);
    
    return (CGSize) {maxOverlayDimension, maxOverlayDimension};
}

- (UIImage *)vignetteImage
{
    if (_vignetteImage) {
        return _vignetteImage;
    }
    
    // setup
    UIColor *vignetteStartColor = [UIColor colorWithMagicIdentifier:@"background.vignette_start_color"];
    UIColor *vignetteEndColor = [UIColor colorWithMagicIdentifier:@"background.vignette_end_color"];

    CGFloat middleColorLocation = [[WAZUIMagic sharedMagic][@"background.vignette_color_position"] floatValue];
    CGFloat vignetteRadiusMultiplier = [[WAZUIMagic sharedMagic][@"background.vignette_radius_multiplier"] floatValue];
    
    UIImage *emptyImage = [UIImage imageWithColor:[UIColor clearColor] andSize:self.vignetteSize];
    _vignetteImage = [UIImage imageVignetteForRect:(CGRect) {{0, 0}, self.vignetteSize}
                                         ontoImage:emptyImage
                            showingImageUnderneath:YES
                                        startColor:vignetteStartColor
                                          endColor:vignetteEndColor
                                     colorLocation:middleColorLocation
                                  radiusMultiplier:vignetteRadiusMultiplier];

    return _vignetteImage;
}

- (UIImage *)vignetteImageNoPicture
{
    if (_vignetteImageNoPicture) {
        return _vignetteImageNoPicture;
    }
 
    UIColor *vignetteStartColor = [UIColor colorWithMagicIdentifier:@"background.vignette_start_color_without_image"];
    UIColor *vignetteEndColor = [UIColor colorWithMagicIdentifier:@"background.vignette_end_color_without_image"];
    
    CGFloat middleColorLocation = [[WAZUIMagic sharedMagic][@"background.vignette_color_position"] floatValue];
    CGFloat vignetteRadiusMultiplier = [[WAZUIMagic sharedMagic][@"background.vignette_radius_multiplier"] floatValue];
    
    
    UIImage *emptyImage = [UIImage imageWithColor:[UIColor clearColor] andSize:self.vignetteSize];
    _vignetteImageNoPicture = [UIImage imageVignetteForRect:(CGRect) {{0, 0}, self.vignetteSize}
                                                  ontoImage:emptyImage
                                     showingImageUnderneath:NO
                                                 startColor:vignetteStartColor
                                                   endColor:vignetteEndColor
                                              colorLocation:middleColorLocation
                                           radiusMultiplier:vignetteRadiusMultiplier];
    
    return _vignetteImageNoPicture;
}

- (void)createInitialConstraints
{
    [self.containerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.darkOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.colorOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.vignetteOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.blurImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.imageView];
    [self.blurImageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.imageView];
    [self.blurImageView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.imageView];
    [self.blurImageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.imageView];
    
    [self.overlayContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)updateOverlayAppearanceWithVisibleImage:(BOOL)showingImage
{
    self.darkOverlay.backgroundColor = showingImage ? [UIColor wr_colorFromColorScheme:ColorSchemeColorBackgroundOverlay] : [UIColor wr_colorFromColorScheme:ColorSchemeColorBackgroundOverlayWithoutPicture];
    self.vignetteOverlay.contentMode = showingImage ? UIViewContentModeScaleToFill : UIViewContentModeScaleAspectFill;
    
    if (showingImage) {
        self.vignetteOverlay.image = self.vignetteImage;
        self.vignetteImageNoPicture = nil;
    }
    else {
        self.vignetteOverlay.image = self.vignetteImageNoPicture;
        self.vignetteImage = nil;
    }
}

- (void)setFilterColor:(UIColor *)filterColor
{
    [self setFilterColor:filterColor animated:YES];
}

- (void)setFilterColor:(UIColor *)filterColor animated:(BOOL)animated
{
    _filterColor = filterColor;
    
    void (^animationBlock)() = ^() {
        self.colorOverlay.backgroundColor = filterColor;
    };
    
    if (animated) {
        NSTimeInterval animationDuration = [WAZUIMagic floatForIdentifier:@"background.animation_duration"];
        [UIView animateWithDuration:animationDuration animations:animationBlock];
    }
    else {
        animationBlock();
    }
}

- (void)setFilterDisabled:(BOOL)filterDisabled
{
    if (_filterDisabled != filterDisabled) {
        _filterDisabled = filterDisabled;
        [self updateAppearanceAnimated:YES];
    }
}

- (void)setBlurPercent:(CGFloat)blurPercent
{
    _blurPercent = blurPercent;
    [self updateBlurAnimated:NO];
}

- (void)setBlurPercentAnimated:(CGFloat)blurPercent
{
    _blurPercent = blurPercent;
    [self updateBlurAnimated:YES];
}

- (void)setBlurDisabled:(BOOL)blurDisabled
{
    if (_blurDisabled != blurDisabled) {
        _blurDisabled = blurDisabled;
        [self updateBlurAnimated:YES];
    }
}

- (BOOL)imageWithCacheIDIsCurrentOrInQueue:(NSString *)cacheID
{
    if ([cacheID isEqualToString:self.blurredImageCacheID] && self.blurredImagePendingCacheID == nil) {
        return YES;
    }
    else if ([self.blurredImageCacheID isEqualToString:cacheID]) {
        return YES;
    }
    
    return NO;
}

- (void)setImageData:(NSData *)imageData withCacheKey:(NSString *)cacheKey animated:(BOOL)animated
{
    [self setImageData:imageData withCacheKey:cacheKey animated:animated waitForBlur:YES];
}

- (void)setImageData:(NSData *)imageData withCacheKey:(NSString *)cacheKey animated:(BOOL)animated
         waitForBlur:(BOOL)waitForBlur
{
    [self setImageData:imageData withCacheKey:cacheKey animated:animated waitForBlur:waitForBlur forceUpdate:NO];
}

- (void)setImageData:(NSData *)imageData withCacheKey:(NSString *)cacheKey animated:(BOOL)animated
         waitForBlur:(BOOL)waitForBlur forceUpdate:(BOOL)forceUpdate
{
    if (! imageData && ! forceUpdate) {
        DDLogInfo(@"Setting nil data on background.");
        return;
    }
    
    self.waitForBlur = waitForBlur;
    
    if (forceUpdate) {
        self.originalImageCacheID = nil;
        self.blurredImageCacheID = nil;
        [self.imageProcessor wipeImageForCacheKey:cacheKey];
    }

    [self transitionToImageWithData:imageData cacheKey:cacheKey animated:animated];
}

- (void)setFlatColor:(UIColor *)color
{
    if (color == nil) {
        return;
    }

    _flatColor = color;
    self.isShowingFlatColor = YES;
    
    [self.imageProcessingQueue cancelAllOperations];
    
    self.imageView.image = nil;
    self.originalImage = nil;
    self.originalImageCacheID = nil;
    self.originalImagePendingCacheID = nil;
    self.blurredImage = nil;
    self.blurredImageCacheID = nil;
    self.blurredImagePendingCacheID = nil;
    
    [self updateAppearanceAnimated:YES];
}

- (void)transitionToImageWithData:(NSData *)imageData
                         cacheKey:(NSString *)cacheKey
                         animated:(BOOL)animated
{
    if ([self imageWithCacheIDIsCurrentOrInQueue:cacheKey]) {
        return;
    }
    
    if (! imageData) {
        return;
    }
    self.isShowingFlatColor = NO;
    
    [self.imageProcessingQueue cancelAllOperations];
    
    self.blurredImagePendingCacheID = cacheKey;
    self.originalImagePendingCacheID = cacheKey;
    
    @weakify(self);
    
    [self.imageProcessor processImageForData:imageData withCacheKey:cacheKey originalCompletion:^(UIImage *image, NSString *imageCacheKey) {
        
        @strongify(self);
        
        if ([self.originalImagePendingCacheID isEqualToString:imageCacheKey]) {
            self.originalImage = image;
            self.originalImageCacheID = imageCacheKey;
            self.originalImagePendingCacheID = nil;
            [self updateAppearanceAnimated:animated];
        }
    } blurCompletion:^(UIImage *image, NSString *imageCacheKey) {
        @strongify(self);
        
        if ([self.blurredImagePendingCacheID isEqualToString:imageCacheKey]) {
            self.blurredImage = image;
            self.blurredImageCacheID = imageCacheKey;
            self.blurredImagePendingCacheID = nil;
            [self updateAppearanceAnimated:animated];
        }
    }];
}

@end



@implementation BackgroundView (Animations)

- (void)updateAppearanceAnimated:(BOOL)animated
{
    [self updateAppearanceInternalAnimated:animated];
    [self updateImagesAnimated:animated];
}

- (void)updateAppearanceInternalAnimated:(BOOL)animated
{
    NSTimeInterval animationDuration = [WAZUIMagic floatForIdentifier:@"background.animation_duration"];
    
    void (^animationBlock)(void) = ^{
        
        if (self.filterDisabled) {
            self.overlayContainer.alpha = 0.0f;
        }
        else {
            self.overlayContainer.alpha = 1.0f;
        }
        
        if (self.isShowingFlatColor) {
            self.imageView.alpha = 0.0f;
            self.blurImageView.alpha = 0.0f;
            self.containerView.backgroundColor = self.flatColor;
            [self updateOverlayAppearanceWithVisibleImage:NO];
        }
        else {
            // Update the blur alpha in case we are switching from a flat color
            [self updateBlurAnimated:animated];
            self.containerView.backgroundColor = nil;
            [self updateOverlayAppearanceWithVisibleImage:YES];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animationBlock];
    }
    else {
        animationBlock();
    }
}

/// Handle cross-fading between background images
- (void)updateImagesAnimated:(BOOL)animated
{
    NSTimeInterval animationDuration = [WAZUIMagic floatForIdentifier:@"background.animation_duration"];

    if (! self.isShowingFlatColor) {
        
        BOOL imagesChanged = self.originalImage != self.imageView.image || self.blurredImage != self.blurImageView.image;
        BOOL haveBothImages = self.blurredImagePendingCacheID == nil && self.originalImagePendingCacheID == nil && self.originalImage != nil && self.blurredImage != nil;
        
        // Only change the images if we have both the blurred and unblurred images and either the normal and blurred images are different
        if (haveBothImages && imagesChanged) {
            if (animated) {
                // Cross fade from the old normal image to the new image
                [UIView transitionWithView:self.imageView
                                  duration:animationDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    self.imageView.image = self.originalImage;
                                } completion:nil];
                
                // Cross fade from the old blurred image to the new image
                [UIView transitionWithView:self.blurImageView
                                  duration:animationDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    self.blurImageView.image = self.blurredImage;
                                } completion:nil];
            }
            else {
                self.imageView.image = self.originalImage;
                self.blurImageView.image = self.blurredImage;
            }
        }
        else if (! self.waitForBlur && self.originalImagePendingCacheID == nil) {
            if (animated) {
                // Cross fade from the old normal image to the new image
                [UIView transitionWithView:self.imageView
                                  duration:animationDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    self.imageView.image = self.originalImage;
                                } completion:nil];
            }
            else {
                self.imageView.image = self.originalImage;
            }
        }
    }
}

@end



@implementation BackgroundView (AnimationsInternal)

- (void)updateBlurAnimated:(BOOL)animated
{
    BOOL forceUnblurred = self.blurDisabled || (self.blurredImagePendingCacheID != nil && ! self.waitForBlur);
    
    CGFloat targetImageAlpha = MIN(1.0, 1.0 - self.blurPercent + 0.6);
    
    // If the filter is disabled and blur is already zero, don't do anything
    if (forceUnblurred && self.blurImageView.alpha == 0.0f) {
        self.imageView.alpha = 1.0;
        return;
    }
    // If the alpha values are already correct, don't do anything
    else if (! forceUnblurred &&
             self.blurImageView.alpha == self.blurPercent &&
             self.imageView.alpha == targetImageAlpha) {
        return;
    }
    
    NSTimeInterval animationDuration = [WAZUIMagic floatForIdentifier:@"background.animation_duration"];
    
    void (^animationBlock)(void) = ^{
        
        if (forceUnblurred) {
            self.blurImageView.alpha = 0.0;
            self.darkOverlay.alpha = 1.0;
            self.imageView.alpha = 1.0;
        }
        else if (self.isShowingFlatColor) {
            self.darkOverlay.alpha = 1.0;
        }
        else {
            self.blurImageView.alpha = self.blurPercent;
            self.darkOverlay.alpha = 1.0;
            self.imageView.alpha = targetImageAlpha;
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animationBlock];
    }
    else {
        animationBlock();
    }
}

@end
