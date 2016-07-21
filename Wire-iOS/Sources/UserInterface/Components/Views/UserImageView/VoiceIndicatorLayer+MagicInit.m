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



#import "VoiceIndicatorLayer+MagicInit.h"
#import "WAZUIMagic.h"
#import "NSDictionary+SimpleTypeAccess.h"
@import WireExtensionComponents;

@implementation VoiceIndicatorLayer (MagicInit)

+ (instancetype)voiceIndicatorLayerWithMagicValuesWithPrefix:(NSString *)prefix ringColor:(UIColor *)color
{
    WAZUIMagic *magic = [WAZUIMagic sharedMagic];
    VoiceIndicatorLayer *indicatorLayer = [VoiceIndicatorLayer layer];

    NSDictionary *circles = magic[[NSString stringWithFormat:@"%@.circles", prefix]];

    for (NSDictionary *circle in circles) {
        PulseLayer *pulseLayer0 = [PulseLayer layer];
        pulseLayer0.backgroundColor = color.CGColor;

        float opacity = [circle floatForKey:@"alpha"];
        pulseLayer0.opacity = opacity;

        ////
        // ALPHA ANIMATION
        ////

        CGFloat alphaDelay = [circle floatForKey:@"alpha_delay"];
        CGFloat alphaAttack = [circle floatForKey:@"alpha_attack"];
        CGFloat alphaSustain = [circle floatForKey:@"alpha_sustain"];
        CGFloat alphaRelease = [circle floatForKey:@"alpha_release"];
        CGFloat alphaHide = [circle floatForKey:@"alpha_hide"];
        CGFloat alphaStart = [circle floatForKey:@"start_alpha"]; // may be missing, 0 is then implied

        pulseLayer0.toOpacity = alphaStart;

        CGFloat totalLength = alphaDelay + alphaAttack + alphaSustain + alphaRelease + alphaHide;

        // Show delay
        AnimationPhase *phase0 = [AnimationPhase animationPhaseWithToValue:alphaStart duration:alphaDelay];
        phase0.layerKeyPathToAnimate = @"opacity"; // only first element needs the keypath, others use the same keypath
        // Show
        AnimationPhase *phase1 = [AnimationPhase animationPhaseWithToValue:alphaStart duration:alphaAttack];
        phase1.timingFunction = kCAMediaTimingFunctionEaseIn;
        // Sustain show/visible
        AnimationPhase *phase2 = [AnimationPhase animationPhaseWithToValue:opacity duration:alphaSustain];
        phase2.timingFunction = kCAMediaTimingFunctionEaseIn;
        // Hide
        AnimationPhase *phase3 = [AnimationPhase animationPhaseWithToValue:opacity duration:alphaRelease];
        phase3.timingFunction = kCAMediaTimingFunctionEaseInEaseOut;
        // Sustain hide
        AnimationPhase *phase4 = [AnimationPhase animationPhaseWithToValue:alphaStart duration:alphaHide];

        NSArray *alphaPhases = @[phase0, phase1, phase2, phase3, phase4];

        ////
        // SCALE ANIMATION
        ////
        CGFloat scaleDelay = [circle floatForKey:@"scale_delay"];
        CGFloat scaleAttack = [circle floatForKey:@"scale_attack"];
        CGFloat scaleRemainder = totalLength - scaleDelay - scaleAttack;

        AnimationPhase *scalePhase0 = [AnimationPhase animationPhaseWithToValue:[circle floatForKey:@"start_scale"] duration:scaleDelay];
        scalePhase0.layerKeyPathToAnimate = @"scale";
        scalePhase0.timingFunction = kCAMediaTimingFunctionEaseOut;
        AnimationPhase *scalePhase1 = [AnimationPhase animationPhaseWithToValue:[circle floatForKey:@"start_scale"] duration:scaleAttack];
        scalePhase1.timingFunction = kCAMediaTimingFunctionEaseOut;
        AnimationPhase *scalePhase2 = [AnimationPhase animationPhaseWithToValue:[circle floatForKey:@"scale"] duration:scaleRemainder];
        scalePhase2.timingFunction = kCAMediaTimingFunctionEaseOut;

        NSArray *scalePhases = @[scalePhase0, scalePhase1, scalePhase2];

        NSDictionary *animationsDict = @{VoicePulsingAlphaAnimation : alphaPhases, VoicePulsingScaleAnimation : scalePhases};

        [indicatorLayer addSublayer:pulseLayer0 withAnimationPhases:animationsDict];
    }

    return indicatorLayer;
}

+ (instancetype)voiceIndicatorLayerForVoiceIndicatorWithMagicValuesWithRingColor:(UIColor *)color
{
    return [[self class] voiceIndicatorLayerWithMagicValuesWithPrefix:@"list.voice_indicator_pulser" ringColor:color];
}

+ (instancetype)voiceIndicatorLayerForVoiceButtonWithMagicValuesWithRingColor:(UIColor *)color
{
    return [[self class] voiceIndicatorLayerWithMagicValuesWithPrefix:@"content.voice_button_pulser" ringColor:color];
}


@end
