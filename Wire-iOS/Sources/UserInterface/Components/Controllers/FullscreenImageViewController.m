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


@import AssetsLibrary;
@import MobileCoreServices;
@import WireExtensionComponents;

#import "FullscreenImageViewController.h"
#import "FullscreenImageViewController+PullToDismiss.h"

// ui
#import "UIView+Borders.h"
#import "IconButton.h"

#import "FLAnimatedImage.h"
#import "FLAnimatedImageView.h"
#import "MediaAsset.h"

#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"
#import "UIViewController+Orientation.h"

// helpers

#import "WAZUIMagiciOS.h"
#import "UIFont+MagicAccess.h"
#import "UIView+MTAnimation.h"
#import "UIColor+WR_ColorScheme.h"
#import "NSString+Wire.h"
#import "NSDate+Format.h"

#import "Constants.h"
#import "UIImage+ZetaIconsNeue.h"
#import <PureLayout/PureLayout.h>

#import "Analytics+iOS.h"

// model
#import "zmessaging+iOS.h"

@interface FirstReponderView : UIView
@end


@implementation FirstReponderView

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];
    return result;
}

@end



@interface FullscreenImageViewController () <UIScrollViewDelegate, ZMVoiceChannelStateObserver>

@property (nonatomic, strong, readwrite) UIScrollView *scrollView;

@property (nonatomic, strong) UIView *topOverlay;
@property (nonatomic, strong) UIView *bottomOverlay;
@property (nonatomic, strong) CALayer *highlightLayer;

@property (nonatomic, strong) UILabel *senderLabel;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) IconButton *closeButton;

@property (nonatomic, strong) IconButton *bottomLeftActionButton;
@property (nonatomic, strong) IconButton *bottomRightActionButton;

@property (nonatomic, strong, readwrite) UIImageView *imageView;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognzier;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, strong) UIPopoverController *popover;

@property (nonatomic, assign) BOOL isShowingChrome;
@property (nonatomic, assign) BOOL assetWriteInProgress;

@property (strong, nonatomic) ALAssetsLibrary *assetLibrary;

@property (nonatomic) CGFloat lastZoomScale;

@property (nonatomic, assign) BOOL forcePortraitMode;

@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;

@property (nonatomic, strong) UIButton *sketchButton;

@end



@implementation FullscreenImageViewController

- (instancetype)initWithMessage:(id<ZMConversationMessage>)message
{
    self = [self init];

    if (self) {
        _message = message;
        _forcePortraitMode = NO;
    }

    return self;
}

- (void)dealloc
{
    [ZMVoiceChannel removeGlobalVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken inUserSession:[ZMUserSession sharedSession]];
}

- (void)loadView
{
    self.view = [[FirstReponderView alloc] init];

    [self setupSnapshotBackgroundView];
    [self setupScrollView];
    [self setupTopOverlay];
    [self setupBottomOverlay];
    [self loadImageAndSetupImageView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateZoomWithSize:self.view.bounds.size];
    [self centerScrollViewContent];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.userInteractionEnabled = YES;
    [self setupGestureRecognizers];
    [self showChrome:YES];

    self.assetLibrary = [[ALAssetsLibrary alloc] init];

    self.voiceChannelStateObserverToken = [ZMVoiceChannel addGlobalVoiceChannelStateObserver:self inUserSession:[ZMUserSession sharedSession]];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)setForcePortraitMode:(BOOL)forcePortraitMode
{
    _forcePortraitMode = forcePortraitMode;
    [UIViewController attemptRotationToDeviceOrientation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)setupSnapshotBackgroundView
{
    self.snapshotBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.snapshotBackgroundView];
    [self.snapshotBackgroundView addConstraintsFittingToView:self.view];
    self.snapshotBackgroundView.alpha = 0;
}

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    [self.scrollView addConstraintsFittingToView:self.view];

    self.automaticallyAdjustsScrollViewInsets = YES;
    self.scrollView.delegate = self;
    self.scrollView.accessibilityIdentifier = @"fullScreenPage";
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.scrollView];
}

- (void)loadImageAndSetupImageView
{
    @weakify(self);
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        @strongify(self);
        
        id<MediaAsset> image;
        const BOOL imageIsAnimatedGIF = self.message.imageMessageData.isAnimatedGIF;
        NSData *imageData = self.message.imageMessageData.imageData;
        
        if (imageIsAnimatedGIF) {
            image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
        }
        else {
            image = [[UIImage alloc] initWithData:imageData];
        }
        
        @weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            
            UIImageView *imageView = [UIImageView imageViewWithMediaAsset:image];
            imageView.clipsToBounds = YES;
            imageView.layer.allowsEdgeAntialiasing = YES;
            
            self.imageView = imageView;
            self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
            [self.scrollView addSubview:self.imageView];
            
            self.scrollView.contentSize = imageView.image.size;
            
            [self centerScrollViewContent];
        });
    });
}

- (void)setupTopOverlay
{
    self.topOverlay = [[UIView alloc] init];
    self.topOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.topOverlay];

    UIView *authorContainer = [[UIView alloc] init];
    authorContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topOverlay addSubview:authorContainer];

    // Sender name

    self.senderLabel = [[UILabel alloc] init];
    self.senderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.senderLabel setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [authorContainer addSubview:self.senderLabel];

    self.senderLabel.accessibilityIdentifier = @"fullScreenSenderName";
    self.senderLabel.attributedText = [self attributedNameStringForDisplayName:self.message.sender.displayName];

    // Timestamp

    self.timestampLabel = [[UILabel alloc] init];
    self.timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.timestampLabel setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [authorContainer addSubview:self.timestampLabel];

    self.timestampLabel.text = [self.message.serverTimestamp extendedFormat];
    self.timestampLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.timestampLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    self.timestampLabel.accessibilityIdentifier = @"fullScreenTimeStamp";
    
    // Close button
    
    self.closeButton = [IconButton iconButtonCircular];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.topOverlay addSubview:self.closeButton];
        
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.closeButton.accessibilityIdentifier = @"fullScreenCloseButton";
    
    // Constraints
    
    [self.topOverlay addConstraintForRightMargin:0 relativeToView:self.view];
    [self.topOverlay addConstraintForLeftMargin:0 relativeToView:self.view];
    [self.topOverlay addConstraintForTopMargin:0 relativeToView:self.view];
    [self.topOverlay addConstraintForHeight:[WAZUIMagic floatForIdentifier:@"one_message.top_gradient_height"]];
    
    [authorContainer addConstraintForLeftMargin:[WAZUIMagic cgFloatForIdentifier:@"one_message.overlay_left_margin"] relativeToView:self.topOverlay];
    [authorContainer addConstraintForAligningRightToLeftOfView:self.closeButton distance:0];
    [authorContainer addConstraintForAligningVerticallyWithView:self.topOverlay offset:10];
    
    [self.closeButton addConstraintForAligningVerticallyWithView:self.topOverlay offset:10];
    [self.closeButton addConstraintForRightMargin:[WAZUIMagic cgFloatForIdentifier:@"one_message.overlay_right_margin"] relativeToView:self.topOverlay];
    [self.closeButton autoSetDimension:ALDimensionWidth toSize:32];
    [self.closeButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.closeButton];
    
    [self.senderLabel addConstraintForLeftMargin:0 relativeToView:authorContainer];
    [self.senderLabel addConstraintForRightMargin:0 relativeToView:authorContainer];
    [self.senderLabel addConstraintForTopMargin:0 relativeToView:authorContainer];
    
    [self.timestampLabel addConstraintForAligningTopToBottomOfView:self.senderLabel distance:0];
    [self.timestampLabel addConstraintForRightMargin:0 relativeToView:authorContainer];
    [self.timestampLabel addConstraintForLeftMargin:0 relativeToView:authorContainer];
    [self.timestampLabel addConstraintForBottomMargin:0 relativeToView:authorContainer];
}

- (void)setupBottomOverlay
{
    self.bottomOverlay = [[UIView alloc] init];
    self.bottomOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomOverlay];

    [self.bottomOverlay addConstraintForRightMargin:0 relativeToView:self.view];
    [self.bottomOverlay addConstraintForLeftMargin:0 relativeToView:self.view];
    [self.bottomOverlay addConstraintForBottomMargin:0 relativeToView:self.view];
    [self.bottomOverlay addConstraintForHeight:[WAZUIMagic floatForIdentifier:@"one_message.bottom_gradient_height"]];


    IconButton *saveButton = [IconButton iconButtonCircular];
    saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [saveButton setIcon:ZetaIconTypeSave withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    IconButton *sketchButton = [IconButton iconButtonCircular];
    sketchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sketchButton setIcon:ZetaIconTypeBrush withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.sketchButton = sketchButton;
    [self.sketchButton addTarget:self action:@selector(editImageTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.sketchButton.accessibilityIdentifier = @"sketchButton";
    

    self.bottomLeftActionButton = saveButton;
    self.bottomRightActionButton = sketchButton;

    [self.bottomOverlay addSubview:self.bottomLeftActionButton];
    [self.bottomLeftActionButton addConstraintForLeftMargin:[WAZUIMagic cgFloatForIdentifier:@"one_message.overlay_left_margin"] relativeToView:self.bottomOverlay];
    [self.bottomLeftActionButton addConstraintForAligningVerticallyWithView:self.bottomOverlay];
    [self.bottomLeftActionButton autoSetDimension:ALDimensionWidth toSize:32];
    [self.bottomLeftActionButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.bottomLeftActionButton];
    
    [self.bottomOverlay addSubview:self.bottomRightActionButton];
    [self.bottomRightActionButton addConstraintForRightMargin:[WAZUIMagic cgFloatForIdentifier:@"one_message.overlay_right_margin"] relativeToView:self.bottomOverlay];
    [self.bottomRightActionButton addConstraintForAligningVerticallyWithView:self.bottomOverlay];
    [self.bottomRightActionButton autoSetDimension:ALDimensionWidth toSize:32];
    [self.bottomRightActionButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.bottomRightActionButton];
    
    self.bottomLeftActionButton.accessibilityIdentifier = @"fullScreenDownloadButton";
}

- (void)showChrome:(BOOL)shouldShow
{
    self.isShowingChrome = shouldShow;
    self.topOverlay.hidden = !shouldShow;
    self.bottomOverlay.hidden = !shouldShow;
}

- (void)setupGestureRecognizers
{
    self.tapGestureRecognzier = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapBackground:)];

    UIGestureRecognizer *delayedTouchBeganRecognizer = self.scrollView.gestureRecognizers[0];
    [delayedTouchBeganRecognizer requireGestureRecognizerToFail:self.tapGestureRecognzier];

    [self.view addGestureRecognizer:self.tapGestureRecognzier];


    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:self.doubleTapGestureRecognizer];

    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.view addGestureRecognizer:self.longPressGestureRecognizer];

    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] init];
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    [panRecognizer addTarget:self action:@selector(dismissingPanGestureRecognizerPanned:)];
    [self.scrollView addGestureRecognizer:panRecognizer];
    
    [self.doubleTapGestureRecognizer requireGestureRecognizerToFail:panRecognizer];
    [self.longPressGestureRecognizer requireGestureRecognizerToFail:panRecognizer];
    [self.tapGestureRecognzier requireGestureRecognizerToFail:panRecognizer];
    [delayedTouchBeganRecognizer requireGestureRecognizerToFail:panRecognizer];
    
    [self.tapGestureRecognzier requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
    [self.tapGestureRecognzier requireGestureRecognizerToFail:self.longPressGestureRecognizer];
}

- (NSAttributedString *)attributedNameStringForDisplayName:(NSString *)displayName
{
    NSString *text = [displayName uppercaseStringWithCurrentLocale];
    NSDictionary *attributes = @{
                                 NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"],
                                 NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground],
                                 NSBackgroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextBackground] };
    
    NSAttributedString *attributedName = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    return attributedName;
}

#pragma mark - UIButtons

- (void)closeButtonTapped:(id)sender
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
    
    if (! IS_IPAD) {
        self.forcePortraitMode = YES;
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)editImageTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(fullscreenImageViewController:wantsEditImageMessage:)]) {
        [self.delegate fullscreenImageViewController:self wantsEditImageMessage:self.message];
    }
}

- (void)saveButtonTapped:(id)sender
{
    if (self.assetWriteInProgress) {return;}

    BOOL didShowSaveAnimation = NO;

    // If authorized to save, run the animation right away.
    // The actual saving should happen concurrently with this.
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        [self performSaveImageAnimationFromSaveButton:sender];
        didShowSaveAnimation = YES;
    }

    __weak __typeof(self) weakSelf = self;

    NSData *imageData = self.message.imageMessageData.imageData;

    self.assetWriteInProgress = YES;

    [self.assetLibrary writeImageDataToSavedPhotosAlbum:imageData
                                               metadata:[self metadataWithImageOrientation:self.imageView.image.imageOrientation]
                                        completionBlock:^(NSURL *assetURL, NSError *error)
            {
                weakSelf.assetWriteInProgress = NO;
                if (!didShowSaveAnimation && ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized)) {
                    // This situation will occur if the user just authorized Wire for photos.
                    // We then run the save animation after user has tapped the button to authorize the app.
                    [weakSelf performSaveImageAnimationFromSaveButton:sender];
                }
            }];
}

- (NSDictionary *)metadataWithImageOrientation:(UIImageOrientation)orientation
{
    int orientationEXIF = 0;

    // Reference:
    // http://sylvana.net/jpegcrop/exif_orientation.html
    // http://www.altdev.co/2011/05/11/adding-metadata-to-ios-images-the-easy-way/
    switch (orientation) {
        case UIImageOrientationUp:
            orientationEXIF = 1;
            break;

        case UIImageOrientationDown:
            orientationEXIF = 3;
            break;

        case UIImageOrientationLeft:
            orientationEXIF = 8;
            break;

        case UIImageOrientationRight:
            orientationEXIF = 6;
            break;

        case UIImageOrientationUpMirrored:
            orientationEXIF = 2;
            break;

        case UIImageOrientationDownMirrored:
            orientationEXIF = 4;
            break;

        case UIImageOrientationLeftMirrored:
            orientationEXIF = 5;
            break;

        case UIImageOrientationRightMirrored:
            orientationEXIF = 7;
            break;
    }

    return @{ALAssetPropertyOrientation : @(orientationEXIF)};
}

- (void)updateZoom
{
    [self updateZoomWithSize:self.view.bounds.size];
}

// Zoom to show as much image as possible unless image is smaller than screen
- (void)updateZoomWithSize:(CGSize)size
{
    float minZoom = MIN(size.width / self.imageView.image.size.width,
                        size.height / self.imageView.image.size.height);

    if (minZoom > 1) {
        minZoom = 1;
    }

    self.scrollView.minimumZoomScale = minZoom;

    // Force scrollViewDidZoom fire if zoom did not change
    if (minZoom == self.lastZoomScale) {
        minZoom += 0.000001;
    }

    self.scrollView.zoomScale = minZoom;
    self.lastZoomScale = minZoom;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self setSelectedByMenu:NO animated:NO];
    [[UIMenuController sharedMenuController] setMenuVisible:NO];

    [self centerScrollViewContent];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)centerScrollViewContent
{
    float imageWidth = self.imageView.image.size.width;
    float imageHeight = self.imageView.image.size.height;

    float viewWidth = self.view.bounds.size.width;
    float viewHeight = self.view.bounds.size.height;
    
    CGFloat horizontalInset = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
    horizontalInset = MAX(0, horizontalInset);
    
    CGFloat verticalInset = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
    verticalInset = MAX(0, verticalInset);
    
    self.scrollView.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
}

#pragma mark - Gesture Handling

- (void)didTapBackground:(UITapGestureRecognizer *)tapper
{
    [self showChrome:!self.isShowingChrome];
    [self setSelectedByMenu:NO animated:NO];
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTapper
{

    [self setSelectedByMenu:NO animated:NO];
    [[UIMenuController sharedMenuController] setMenuVisible:NO];


    CGPoint point = [doubleTapper locationInView:doubleTapper.view];

    CGRect zoomRect = CGRectMake(point.x - 25, point.y - 25, 50, 50);

    CGRect finalRect = [self.imageView convertRect:zoomRect fromView:doubleTapper.view];

    CGFloat scaleDiff = self.scrollView.zoomScale - self.scrollView.minimumZoomScale;

    if (scaleDiff < 0.0003) {
        [self.scrollView zoomToRect:finalRect animated:YES];
    } else {
        [self.scrollView setZoomScale:self.lastZoomScale animated:YES];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer
{
    if ([longPressRecognizer state] == UIGestureRecognizerStateBegan) {

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuDidHide:)
                                                     name:UIMenuControllerDidHideMenuNotification object:nil];


        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [self.view becomeFirstResponder];
        [menuController setTargetRect:self.imageView.bounds inView:self.imageView];
        [menuController setMenuVisible:YES animated:YES];
        [self setSelectedByMenu:YES animated:YES];
    }
}


#pragma mark - Copy/Paste

- (BOOL)canPerformAction:(SEL)action
              withSender:(id)sender
{
    if (action == @selector(cut:)) {
        return NO;
    }
    else if (action == @selector(copy:)) {
        return YES;
    }
    else if (action == @selector(paste:)) {
        return NO;
    }
    else if (action == @selector(select:) || action == @selector(selectAll:)) {
        return NO;
    }

    return [super canPerformAction:action withSender:sender];
}

- (void)copy:(id)sender
{
    [[Analytics shared] tagOpenedMessageAction:MessageActionTypeCopy];
    [[Analytics shared] tagMessageCopy];
    [[UIPasteboard generalPasteboard] setMediaAsset:[self.imageView mediaAsset]];
}

- (void)setSelectedByMenu:(BOOL)selected animated:(BOOL)animated
{
    DDLogDebug(@"Setting selected: %@ animated: %@", @(selected), @(animated));
    if (selected) {

        self.highlightLayer = [CALayer layer];
        self.highlightLayer.backgroundColor = [UIColor clearColor].CGColor;
        self.highlightLayer.frame = CGRectMake(0, 0, self.imageView.frame.size.width / self.scrollView.zoomScale, self.imageView.frame.size.height / self.scrollView.zoomScale);
        [self.imageView.layer insertSublayer:self.highlightLayer atIndex:0];

        if (animated) {

            [UIView animateWithDuration:0.33 animations:^{

                self.highlightLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;

            }];
        }
        else {

            self.highlightLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
        }
    }
    else {

        if (animated) {

            [UIView animateWithDuration:0.33 animations:^{

                self.highlightLayer.backgroundColor = [UIColor clearColor].CGColor;;

            }                completion:^(BOOL finished){

                if (finished) {

                    [self.highlightLayer removeFromSuperlayer];
                }
            }];
        }
        else {

            self.highlightLayer.backgroundColor = [UIColor clearColor].CGColor;
            [self.highlightLayer removeFromSuperlayer];

        }
    }
}

- (void)menuDidHide:(NSNotification *)notification
{

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerDidHideMenuNotification object:nil];

    [self setSelectedByMenu:NO animated:YES];
}


#pragma mark - Utilities, custom UI

- (void)performSaveImageAnimationFromSaveButton:(UIButton *)saveButton
{
    UIImageView *ghostImageView = [[UIImageView alloc] initWithImage:self.imageView.image];
    ghostImageView.contentMode = UIViewContentModeScaleAspectFit;
    ghostImageView.translatesAutoresizingMaskIntoConstraints = YES;
    CGRect initialFrame = [self.view convertRect:self.imageView.frame fromView:self.imageView.superview];
    [self.view addSubview:ghostImageView];
    ghostImageView.frame = initialFrame;
    CGPoint targetCenter = [self.view convertPoint:saveButton.center fromView:saveButton.superview];

    [UIView mt_animateWithViews:@[ghostImageView] duration:0.55 timingFunction:kMTEaseInExpo animations:^{
        ghostImageView.center = targetCenter;
        ghostImageView.alpha = 0;
        ghostImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    }                completion:^{
        [ghostImageView removeFromSuperview];
    }];
}

/// Special check in case we get an incoming voice call and we are looking at this view in ipad landscape
- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)change
{
    if (change.voiceChannel.state == ZMVoiceChannelStateIncomingCall && IS_IPAD_LANDSCAPE_LAYOUT) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
