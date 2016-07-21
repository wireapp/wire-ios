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
// This module of the Wire Software uses software code from Heiko Dreyer
// governed by the MIT license (https://github.com/bfolder/UIView-Visuals).
//
//
//  CAMediaTimingFunction+AdditionalEquations.h
//
//  Created by Heiko Dreyer on 02.04.12.
//  Copyright (c) 2012 boxedfolder.com. All rights reserved.
//
//// UIView-Visuals is licensed under MIT License.
//// Permission is hereby granted, free of charge, to any person obtaining a copy of this
//// software and associated documentation files (the "Software"), to deal in the Software
//// without restriction, including without limitation the rights to use, copy, modify, merge,
//// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//// to whom the Software is furnished to do so, subject to the following conditions:
////
//// The above copyright notice and this permission notice shall be included in all copies or substantial
//// portions of the Software.

//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
//// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import <QuartzCore/QuartzCore.h>

@interface CAMediaTimingFunction (AdditionalEquations)


///---------------------------------------------------------------------------------------
/// @name Circ Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInCirc;
+(CAMediaTimingFunction *)easeOutCirc;
+(CAMediaTimingFunction *)easeInOutCirc;

///---------------------------------------------------------------------------------------
/// @name Cubic Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInCubic;
+(CAMediaTimingFunction *)easeOutCubic;
+(CAMediaTimingFunction *)easeInOutCubic;

///---------------------------------------------------------------------------------------
/// @name Expo Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInExpo;
+(CAMediaTimingFunction *)easeOutExpo;
+(CAMediaTimingFunction *)easeInOutExpo;

///---------------------------------------------------------------------------------------
/// @name Quad Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInQuad;
+(CAMediaTimingFunction *)easeOutQuad;
+(CAMediaTimingFunction *)easeInOutQuad;

///---------------------------------------------------------------------------------------
/// @name Quart Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInQuart;
+(CAMediaTimingFunction *)easeOutQuart;
+(CAMediaTimingFunction *)easeInOutQuart;

///---------------------------------------------------------------------------------------
/// @name Quint Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInQuint;
+(CAMediaTimingFunction *)easeOutQuint;
+(CAMediaTimingFunction *)easeInOutQuint;

///---------------------------------------------------------------------------------------
/// @name Sine Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInSine;
+(CAMediaTimingFunction *)easeOutSine;
+(CAMediaTimingFunction *)easeInOutSine;

///---------------------------------------------------------------------------------------
/// @name Back Easing
///---------------------------------------------------------------------------------------

+(CAMediaTimingFunction *)easeInBack;
+(CAMediaTimingFunction *)easeOutBack;
+(CAMediaTimingFunction *)easeInOutBack;

@end
