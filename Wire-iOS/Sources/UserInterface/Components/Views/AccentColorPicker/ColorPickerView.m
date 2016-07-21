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


#import "ColorPickerView.h"

#import "ColorBandsView.h"
#import "ColorPickerKnobView.h"
#import "IdentifiableColor.h"



@interface ColorPickerView ()

@property (strong, nonatomic, readwrite) NSArray *colors;

/* Color borders must be at pixel boundaries, so we floor the computation of the width of one band. But this means that
 the whole color strip will end up being shorter than the view width. To compensate, we add one unit to each band width
 in sequence until it adds up to the correct width. We do this computation once and store the results here, and all
 subviews/layers can use this. */
@property (strong, nonatomic) NSMutableArray *colorBandWidthsBacking;

@property (strong, nonatomic, readwrite) ColorBandsView *bandsView;
@property (nonatomic, strong, readwrite) ColorPickerKnobView *knobView;
@property (strong, nonatomic, readwrite) UIView *ghostKnobView;

@end



@implementation ColorPickerView

- (instancetype)initWithColors:(NSArray *)colors
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // Initialization code
        self.colors = colors;
        
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.0];

    // add the bands view
    
    NSMutableArray *justColors = [[NSMutableArray alloc] init];
    [self.colors enumerateObjectsUsingBlock:^(IdentifiableColor *idColor, NSUInteger idx, BOOL *stop) {
        [justColors addObject:idColor.color];
    }];

    self.bandsView = [[ColorBandsView alloc] initWithColors:justColors];    
    self.bandsView.colorBandWidths = self.colorBandWidths;
    self.bandsView.userInteractionEnabled = NO;
    [self addSubview:self.bandsView];

    // add the knob view on top
    CGFloat knobSize = 40;
    self.knobView = [[ColorPickerKnobView alloc] initWithFrame:CGRectMake(0, 20, knobSize, knobSize)];
    [self addSubview:self.knobView];

    self.ghostKnobView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, knobSize, knobSize)];
    self.ghostKnobView.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
    self.ghostKnobView.userInteractionEnabled = NO;
    [self addSubview:self.ghostKnobView];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    if (! hidden) {
        [self relayoutKnobAndColorBandsFromGestureHandler];
    }
}

- (void)layoutSubviews
{
    // The bounds may have changed, so we need to recompute the band widths
    [self recomputeColorBandWidths];

    [super layoutSubviews];

    CGFloat bandsHeight = 2;
    CGFloat bandsY = (self.bounds.size.height - bandsHeight) / 2;

    self.bandsView.frame = CGRectMake(0, bandsY, self.bounds.size.width, bandsHeight);

    CGPoint center = self.knobView.center;
    center.y = self.bounds.size.height / 2;
    self.knobView.center = center;
    self.ghostKnobView.center = self.knobView.center;
}


- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 56.0f);
}

- (void)recomputeColorBandWidths
{
    // recompute
    self.colorBandWidthsBacking = [NSMutableArray array];

    CGFloat width = self.bounds.size.width;

    CGFloat bandWidth = floor(width / self.colors.count);

    for (NSUInteger i = 0; i < self.colors.count; i ++) {
        self.colorBandWidthsBacking[i] = @(bandWidth);
    }

    NSUInteger index = 0;
    CGFloat pointsToAdd = 1;
    while ([[self.colorBandWidths valueForKeyPath:@"@sum.floatValue"] floatValue] < width) {
        CGFloat f = [self.colorBandWidths[index] floatValue];
        f += pointsToAdd;
        self.colorBandWidthsBacking[index] = @(f);
        index ++;
        if (index == self.colors.count) {
            index = 0;
        }
    }

    // reassign to children
    self.bandsView.colorBandWidths = self.colorBandWidthsBacking;
}

- (NSArray *)colorBandWidths
{
    return self.colorBandWidthsBacking;
}


- (void)relayoutKnobAndColorBandsFromAnimationCallback
{
    [self repositionRealKnobBasedOnGhost];
    [self recomputeKnobLayout];
    [self updateColorBandMask];
}

- (void)relayoutKnobAndColorBandsFromGestureHandler
{
    [self repositionGhostKnobBasedOnReal];
    [self recomputeKnobLayout];
    [self updateColorBandMask];
}

#pragma mark - Utilities

// Reposition the real knob based on the ghost presentation value (which is driven by CoreAnimation)
- (void)repositionRealKnobBasedOnGhost
{
    ColorPickerKnobView *knob = self.knobView;
    knob.center = ((CALayer *) self.ghostKnobView.layer.presentationLayer).position;
}

- (void)repositionGhostKnobBasedOnReal
{
    self.ghostKnobView.center = self.knobView.center;
}

- (void)updateColorBandMask
{
    ColorPickerView *colorPickerView = self;
    ColorPickerKnobView *knob = self.knobView;

    CGFloat circleWidth = 24;
    CGFloat circleLeftEdge = knob.center.x - circleWidth / 2;
    CGFloat circleRightEdge = circleLeftEdge + circleWidth;

    // compensate a bit for the overlay
    CGFloat compensator = 1;
    circleRightEdge -= 2 * compensator;
    circleLeftEdge += compensator;

    CGFloat h = colorPickerView.bandsView.bounds.size.height;
    CGFloat rightEdge = CGRectGetMaxX(self.bounds);

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:(CGPoint) {0, 0}];
    [path addLineToPoint:(CGPoint) {circleLeftEdge, 0}];
    [path addLineToPoint:(CGPoint) {circleLeftEdge, h}];
    [path addLineToPoint:(CGPoint) {0, h}];
    [path closePath];

    [path moveToPoint:(CGPoint) {circleRightEdge, 0}];
    [path addLineToPoint:(CGPoint) {rightEdge, 0}];
    [path addLineToPoint:(CGPoint) {rightEdge, h}];
    [path addLineToPoint:(CGPoint) {circleRightEdge, h}];
    [path closePath];

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    colorPickerView.bandsView.layer.mask = shapeLayer;
}

- (void)recomputeKnobLayout
{
    // Following code relies on color array is mapped on colorBandWidths array, so ensure those are in sync here.
    [self recomputeColorBandWidths];
    
    // Recalculate the colors

    CGFloat x = ((CALayer *) self.knobView.layer.presentationLayer).position.x;

    CGFloat radius = 12;
    CGFloat circleLeftEdge = x - radius + .01;
    CGFloat circleRightEdge = x + radius - .01;

    CGFloat rightOffset = self.bounds.size.width;
    if (rightOffset == 0) {return;}

    NSInteger leftIndex = - 1;
    CGFloat leftOffset = 0;

    while (leftOffset < circleLeftEdge) {
        
        NSUInteger nextIndex = leftIndex + 1;
        if (nextIndex >= self.colorBandWidths.count) {
            break;
        }
        else {
            leftOffset += [self.colorBandWidths[leftIndex + 1] floatValue];
        }
        leftIndex ++;
    }
    
    leftIndex = MIN(leftIndex, (NSInteger)self.colors.count - 1);
    leftIndex = MAX(leftIndex, 0);

    // compute right color index
    
    NSInteger rightIndex = self.colors.count - 1;
    while (rightOffset > circleRightEdge && rightIndex >= 0) {
        rightOffset -= [self.colorBandWidths[rightIndex] floatValue];
        rightIndex --;
    }
    rightIndex++;
    rightIndex = MIN(rightIndex, (NSInteger)self.colors.count - 1);
    rightIndex = MAX(rightIndex, 0);
    
    // compute proportion

    IdentifiableColor *leftIdColor = self.colors[leftIndex];
    IdentifiableColor *rightIdColor = self.colors[rightIndex];
    self.knobView.leftColor = leftIdColor.color;
    self.knobView.rightColor = rightIdColor.color;

    CGFloat middlePoint = NSNotFound;
    NSUInteger middleIndex = 0;
    CGFloat proposedMiddlePoint = 0;
    
    while (middleIndex < self.colorBandWidths.count) {
        proposedMiddlePoint += [self.colorBandWidths[middleIndex] floatValue];
        if ((proposedMiddlePoint > circleLeftEdge) && (proposedMiddlePoint < circleRightEdge)) {
            middlePoint = proposedMiddlePoint;
            break;
        }
        middleIndex ++;
    }

    if (middlePoint != NSNotFound) {

        CGFloat circleCenterDelta = middlePoint - x;
        CGFloat h = sqrt(pow(radius, 2) - pow(circleCenterDelta, 2));
        CGFloat hScaled = h / radius;

        double portionToDraw = asin(hScaled);
        if (circleCenterDelta < 0) {
            self.knobView.leftProportion = portionToDraw / M_PI;
        } else {
            self.knobView.leftProportion = (- portionToDraw + M_PI) / M_PI;
        }
    }

    if (self.knobView.leftColor == self.knobView.rightColor) {
        IdentifiableColor *leftColor = [self.colors wr_identifiableColorByColor:self.knobView.leftColor];
        [self.delegate colorPickerViewDisplayedColorChangedTo:leftColor];
    } else {
        if (self.knobView.leftProportion > 0.5) {
            [self.delegate colorPickerViewDisplayedColorChangedTo:[self.colors wr_identifiableColorByColor:self.knobView.leftColor]];
        } else {
            [self.delegate colorPickerViewDisplayedColorChangedTo:[self.colors wr_identifiableColorByColor:self.knobView.rightColor]];
        }
    }
}

@end
