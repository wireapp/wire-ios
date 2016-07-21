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

@class ColorPickerKnobView;
@class ColorBandsView;
@class IdentifiableColor;
@protocol ColorPickerViewDelegate;



@interface ColorPickerView : UIView

@property (strong, nonatomic, readonly) ColorBandsView *bandsView;
@property (nonatomic, strong, readonly) ColorPickerKnobView *knobView;

/// NSArray of boxed @c IdentifiableColor values
@property (strong, nonatomic, readonly) NSArray *colors;

@property (weak, nonatomic) id <ColorPickerViewDelegate> delegate;

/// This will be driving animations. CoreAnimation positions it, and our code picks up the presentation layer values with displayLink. 
@property (strong, nonatomic, readonly) UIView *ghostKnobView;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithColors:(NSArray *)colors NS_DESIGNATED_INITIALIZER;

- (NSArray *)colorBandWidths;

- (void)relayoutKnobAndColorBandsFromAnimationCallback;
- (void)relayoutKnobAndColorBandsFromGestureHandler;

@end


@protocol ColorPickerViewDelegate <NSObject>

/// The color that the view is displaying changed to this color. “Displayed” means “knob focus”. It has nothing to do with what’s the user’s actual accent color.
- (void)colorPickerViewDisplayedColorChangedTo:(IdentifiableColor *)color;

@end
