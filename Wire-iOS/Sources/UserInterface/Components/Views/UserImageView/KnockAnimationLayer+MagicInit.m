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



#import "KnockAnimationLayer+MagicInit.h"
#import "WAZUIMagic.h"
#import "NSDictionary+SimpleTypeAccess.h"


@implementation KnockAnimationLayer (MagicInit)

+ (instancetype)knockAnimationLayerWithMagicValuesWithCircleColor:(UIColor *)color
{
    WAZUIMagic *magic = [WAZUIMagic sharedMagic];
    KnockAnimationLayer *knockAnimationLayer = [KnockAnimationLayer layer];
    knockAnimationLayer.circleColor = color;

    NSArray *rawStepsArray = magic[@"content.knocking_indicator.steps"];
    if (! rawStepsArray || 0 == [rawStepsArray count]) {
        return knockAnimationLayer;
    }
    NSMutableArray *stepsArray = [NSMutableArray array];
    for (id obj in rawStepsArray) {
        if (NO == [obj isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *stepDictionary = (NSDictionary *) obj;
        CGFloat alpha = [stepDictionary floatForKey:@"alpha"];
        CGFloat scale = [stepDictionary floatForKey:@"scale"];
        CGFloat duration = [stepDictionary floatForKey:@"duration"];
        BOOL startFromLastStepBounds = [stepDictionary boolForKey:@"start_from_last_step_size"];

        KnockAnimationStep *step = [KnockAnimationStep knockAnimationStep];
        step.toOpacity = alpha;
        step.toContentsScale = scale;
        step.duration = duration;
        step.startFromLastStepBounds = startFromLastStepBounds;

        [stepsArray addObject:step];
    }

    knockAnimationLayer.animationSteps = [NSArray arrayWithArray:stepsArray];

    return knockAnimationLayer;
}

@end
