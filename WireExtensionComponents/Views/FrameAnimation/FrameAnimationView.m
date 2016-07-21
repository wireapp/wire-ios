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




#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "FrameAnimationView.h"
#import "Geometry.h"



static __strong CADisplayLink *GlobalDisplayLink = nil;



static NSMutableDictionary *FrameDataCache;
static NSTimeInterval LastVSyncTime = 0;
static NSTimeInterval CurrentVSyncDelta = 0;
static NSMutableSet  *Animations;
static float          DesignedFPS = 60.0f;

@interface FrameAnimationView ()

@property (nonatomic, strong) NSArray   *frameInfo;
@property (nonatomic, assign) CGFloat    currentFrame;
@property (nonatomic, assign) CGImageRef image;
@property (nonatomic, assign) CGImageRef tintedImage;
@property (nonatomic, assign) NSInteger  imageWidth;
@property (nonatomic, assign) NSInteger  imageHeight;


@property (nonatomic, assign) BOOL isRepeating;

@property (nonatomic, assign) NSUInteger desiredFastForwardFrame;
@property (nonatomic, assign) BOOL doingFastForward;
@property (nonatomic, copy)   dispatch_block_t fastForwardCompletionBlock;

+ (void)nextFrame:(id)sender;
@end



#if !TARGET_OS_IPHONE
static CVReturn renderCallback(CVDisplayLinkRef displayLink,
                               const CVTimeStamp *inNow,
                               const CVTimeStamp *inOutputTime,
                               CVOptionFlags flagsIn,
                               CVOptionFlags *flagsOut,
                               void *displayLinkContext)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [(__bridge id)displayLinkContext nextFrame:nil];
    });
    return kCVReturnSuccess;
}
#endif

@implementation FrameAnimationView

#pragma mark - Static methods

+ (void)initialize
{
    [super initialize];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        GlobalDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(nextFrame:)];
        GlobalDisplayLink.paused = YES;
        [GlobalDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        FrameDataCache = [NSMutableDictionary new];
    });
    
    if (Animations == nil) {
        Animations = [[NSMutableSet alloc] init];
    }
}

+ (void)startDisplayLink
{
    LastVSyncTime = CACurrentMediaTime();
    GlobalDisplayLink.paused = NO;
}

+ (void)stopDisplayLink
{
    GlobalDisplayLink.paused = YES;
}

+ (void)nextFrame:(id)sender
{
    NSTimeInterval CurrentVSyncTime = CACurrentMediaTime();
    CurrentVSyncDelta = CurrentVSyncTime - LastVSyncTime;
    
    for (FrameAnimationView *animation in [Animations copy]) {
        [animation advanceFrame];
    }
    LastVSyncTime = CurrentVSyncTime;
}

+ (void)subscribeToTimer:(FrameAnimationView *)animation
{
    if (Animations.count == 0) {
        [self startDisplayLink];
    }
    [Animations addObject:animation];
}

+ (void)unsubscribeFromTimer:(FrameAnimationView *)animation
{
    [Animations removeObject:animation];
    if (Animations.count == 0) {
        [self stopDisplayLink];
    }
}

+ (BOOL)isAnimationPlaying:(FrameAnimationView *)animation
{
    return [Animations containsObject:animation];
}

#pragma mark - Setup / teardown

+ (instancetype)frameAnimationNamed:(NSString *)name repeat:(BOOL)isRepeating
{
    return [[self alloc] initWithName:name repeat:isRepeating];
}

- (instancetype)initWithName:(NSString *)resourceName repeat:(BOOL)isRepeating
{
    return [self initWithFrame:CGRectZero name:resourceName repeat:isRepeating];
}

- (instancetype)initWithFrame:(CGRect)frame name:(NSString *)resourceName repeat:(BOOL)isRepeating
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isRepeating = isRepeating;
        self.framesPerTick = 1.0f;
        [self setupAnimation:resourceName];
    }
    
    return self;
}

- (void)setupLayer
{
    self.layer.contents = (id) self.image;
    
    NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"contentsRect",
                                       nil];
    self.layer.actions = newActions;
    self.layer.contentsRect = CGRectMake(1.0, 1.0, 0, 0);
}

- (void)setupAnimation:(NSString *)name
{
    [self loadFrameData:name];
    [self loadImage:name];
    [self setupLayer];
}

- (void)dealloc {
    CFRelease(_image);
    CFRelease(_tintedImage);
    [self stopPlaying];
}

#pragma mark - Accessors

- (BOOL)isPlaying
{
    return [self.class isAnimationPlaying:self];
}

- (void)startPlaying
{
    [[self class] subscribeToTimer:self];
}

- (void)stopPlaying
{
    [[self class] unsubscribeFromTimer:self];
}

- (void)resetPlayer
{
    self.currentFrame = 0;
}

- (NSUInteger)frameCount
{
    return self.frameInfo.count;
}

- (NSUInteger)lastFrame
{
    return self.frameInfo.count - 1;
}

- (NSTimeInterval)duration
{
    return self.frameInfo.count / DesignedFPS;
}

- (void)setTintColor:(Color *)color
{
    _tintColor = color;
    
    [self applyTintColor];
}

- (void)setImage:(CGImageRef)image
{
    if (_image != nil) {
        CFRelease(_image);
    }
    _image = image;
    if (_image != nil) {
        CFRetain(_image);
    }
    [self applyTintColor];
}

- (void)setTintedImage:(CGImageRef)tintedImage
{
    if (_tintedImage != nil) {
        CFRelease(_tintedImage);
    }
    _tintedImage = tintedImage;
    if (_tintedImage != nil) {
        CFRetain(_tintedImage);
    }
    
    self.layer.contents = (id) self.tintedImage;
}

#pragma mark - Frame change

- (void)fastForwardToFrame:(NSUInteger)frame in:(NSTimeInterval)seconds onCompletion:(dispatch_block_t)completion
{
    if (seconds == 0.0f) {
        self.currentFrame = self.lastFrame;
        [self showFrame:self.currentFrame];
        if (nil != completion) {
            completion();
        }
    }
    else {
        CGFloat diff = 0;
        diff = self.frameInfo.count - roundf(self.currentFrame);
        
        if (diff / DesignedFPS >= seconds) {
            CGFloat fps = diff / seconds;
            self.framesPerTick = fps / DesignedFPS;
        }
        
        if (frame <= self.currentFrame) {
            if (nil != completion) {
                completion();
            }
        }
        else {
            self.desiredFastForwardFrame = frame;
            self.doingFastForward = YES;
            self.fastForwardCompletionBlock = completion;
        }
    }
}

- (void)advanceFrame
{
    NSUInteger frameNum = 0;
    frameNum = roundf(self.currentFrame);
    [self showFrame:frameNum];
    
    NSTimeInterval normalVSyncDelta = 1.0f / DesignedFPS;
    double frameStep = self.framesPerTick * (CurrentVSyncDelta / normalVSyncDelta);
    self.currentFrame+= frameStep;
    
    if (self.doingFastForward) {
        if (self.currentFrame >= self.desiredFastForwardFrame) {
            if (self.fastForwardCompletionBlock != nil) {
                self.fastForwardCompletionBlock();
            }
            
            self.desiredFastForwardFrame = 0;
            self.fastForwardCompletionBlock = nil;
            self.doingFastForward = NO;
            [self stopPlaying];
        }
    }
    else {
        if (self.currentFrame >= self.frameInfo.count) {
            if (self.isRepeating) {
                [self resetPlayer];
            }
            else {
                if (nil != self.onFinished) {
                    self.onFinished(self);
                }
                [self stopPlaying];
            }
        }
    }
}

- (void)showFrame:(NSUInteger)frameNum
{
    if (frameNum >= self.frameInfo.count) {
        frameNum = self.frameInfo.count - 1;
    }
    
    NSDictionary *currentFrameData = self.frameInfo[frameNum][@"frame"];
    CGRect rect = [self rectForDictionary:currentFrameData];
    
    CGSize normalizedSize = CGSizeMake( rect.size.width / self.imageWidth, rect.size.height / self.imageHeight );
    
    CGFloat nX = rect.origin.x / self.imageWidth;
    
    CGFloat nY = rect.origin.y / self.imageHeight;
    
    CGRect finalRect = CGRectMake(nX, nY, normalizedSize.width, normalizedSize.height);
    self.layer.contentsRect = finalRect;
}

#pragma mark - Private

- (CGRect)rectForDictionary:(NSDictionary *)dimensions
{
    CGRect rect = CGRectMake([dimensions[@"x"] integerValue], [dimensions[@"y"] integerValue], [dimensions[@"w"] integerValue], [dimensions[@"h"] integerValue]);
    return rect;
}

- (void)applyTintColor
{
    if (self.image == nil || self.tintColor == nil) {
        self.tintedImage = self.image;
        return;
    }
    
    CIColor *ciColor = [[CIColor alloc] initWithColor:self.tintColor];
    
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:self.image];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"];
    [filter setDefaults];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:[CIVector vectorWithX:ciColor.red Y:0 Z:0 W:0] forKey:@"inputRVector"];
    [filter setValue:[CIVector vectorWithX:0 Y:ciColor.green Z:0 W:0] forKey:@"inputGVector"];
    [filter setValue:[CIVector vectorWithX:0 Y:0 Z:ciColor.blue W:0] forKey:@"inputBVector"];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    self.tintedImage = [context createCGImage:result fromRect:[result extent]];
}

- (void)loadFrameData:(NSString *)name
{
    NSDictionary *animationData = FrameDataCache[name];
    if (animationData == nil) {
        NSError *error = nil;
        
        float displayScale = 1;
        displayScale = [UIScreen mainScreen].nativeScale;
        
        NSString *postfix = @"";
        
        if (displayScale == 2) {
            postfix = @"@2x";
        }
        
        NSString *jsonName = [NSString stringWithFormat:@"%@%@", name, postfix];
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:jsonName ofType:@"json"];
        
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        if (jsonData.length == 0 && postfix.length != 0) {
            postfix = @"";
            jsonName = [NSString stringWithFormat:@"%@%@", name, postfix];
            jsonPath = [[NSBundle mainBundle] pathForResource:jsonName ofType:@"json"];
            
            jsonData = [NSData dataWithContentsOfFile:jsonPath];
        }
        animationData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        FrameDataCache[name] = animationData;
    } else {
        self.frameInfo = animationData[@"frames"];
    }
}

- (void)loadImage:(NSString *)name
{
    UIImage *image = [UIImage imageNamed:name];
    self.image = CGImageRetain(image.CGImage);

    self.imageWidth = CGImageGetWidth(self.image);
    self.imageHeight = CGImageGetHeight(self.image);
}

@end
