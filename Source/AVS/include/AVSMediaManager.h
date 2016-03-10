
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


#import "AVSMedia.h"


void AVSDebug ( NSString *message, ... );
void AVSWarn ( NSString *message, ... );
void AVSError ( NSString *message, ... );

void AVSLog ( NSInteger level, NSString *message, ... );
void AVSOut ( NSInteger level, NSString *message, va_list arguments );


typedef NS_ENUM (NSUInteger, AVSPlaybackMode) {
    AVSPlaybackModeUnknown,
    AVSPlaybackModeOn,
    AVSPlaybackModeOff
};

typedef NS_ENUM (NSUInteger, AVSPlaybackRoute) {
    AVSPlaybackRouteUnknown,
    AVSPlaybackRouteBuiltIn,
    AVSPlaybackRouteHeadset,
    AVSPlaybackRouteSpeaker
};

typedef NS_ENUM (NSUInteger, AVSRecordingMode){
    AVSRecordingModeUnknown,
    AVSRecordingModeOn,
    AVSRecordingModeOff
};

typedef NS_ENUM (NSUInteger, AVSRecordingRoute) {
    AVSRecordingRouteUnknown,
    AVSRecordingRouteBuiltIn,
    AVSRecordingRouteHeadset
};


typedef NS_ENUM (NSUInteger, AVSIntensityLevel) {
    AVSIntensityLevelNone = 0,
    AVSIntensityLevelSome = 50,
    AVSIntensityLevelFull = 100
};


@class AVSMediaManager;

@class AVSMediaManagerChangeNotification;


@protocol AVSMediaManagerObserver <NSObject>

- (void)avsMediaManagerDidChange:(AVSMediaManagerChangeNotification *)notification;

@end


@interface AVSMediaManagerChangeNotification : NSNotification

@property (nonatomic, readonly) AVSMediaManager *avsMediaManager;
/*
@property (nonatomic, readonly) BOOL interruptChanged;

@property (nonatomic, readonly) BOOL intensityChanged;

@property (nonatomic, readonly) BOOL playbackMuteChanged;
@property (nonatomic, readonly) BOOL recordingMuteChanged;

@property (nonatomic, readonly) BOOL playbackModeChanged;
@property (nonatomic, readonly) BOOL recordingModeChanged;
*/
@property (nonatomic, readonly) BOOL playbackRouteChanged;
@property (nonatomic, readonly) BOOL recordingRouteChanged;
/*
@property (nonatomic, readonly) BOOL preferredPlaybackRouteChanged;
@property (nonatomic, readonly) BOOL preferredRecordingRouteChanged;
*/
+ (void)addObserver:(id <AVSMediaManagerObserver>)observer;
+ (void)removeObserver:(id <AVSMediaManagerObserver>)observer;

@end


@interface AVSMediaManager : NSObject

@property (nonatomic) AVSPlaybackRoute playbackRoute;

+ (instancetype)defaultMediaManager;
- (void)playMediaByName:(NSString *)name;
- (void)stopMediaByName:(NSString *)name;

- (void)internalRegisterMediaFromConfiguration:(NSDictionary *)configuration inDirectory:(NSString *)directory;
- (void)registerMedia:(id<AVSMedia>)media withOptions:(NSDictionary *)options;
- (void)unregisterMedia:(id<AVSMedia>)media;

- (BOOL)isInterrupted;

- (AVSIntensityLevel)intensity;
- (void)setIntensity:(AVSIntensityLevel)intensity;

- (BOOL)isPlaybackMuted;
- (void)setPlaybackMuted:(BOOL)muted;

- (void)enableSpeaker:(BOOL)speakerEnabled;

- (AVSRecordingRoute)recordingRoute;

- (void)setCallState:(BOOL)inCall forConversation:(NSString *)convId;

- (void)setVideoCallState:(NSString *)convId;

@end
