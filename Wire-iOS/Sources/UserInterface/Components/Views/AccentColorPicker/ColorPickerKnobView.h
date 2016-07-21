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



@interface ColorPickerKnobView : UIView

/* These properties define multi-color knob drawing. The names are straightforward.
 The left proportion is fractional and should be <= 1 (100%). The right proportion is calculated automatically
 as 1-leftProportion. In case of a single color, define both colors to be the same
 and the fractions are ignored in that case. */

@property (nonatomic, strong) UIColor *leftColor;
@property (nonatomic, strong) UIColor *rightColor;
@property (nonatomic, assign) CGFloat leftProportion;

// Whether user is currently dragging the knob
@property (nonatomic, assign) BOOL pickedUp;

@end
