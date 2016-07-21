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


@import UIKit;



@class TextViewWithDataDetectorWorkaround;



@protocol TextViewInteractionDelegate <NSObject>
- (void)textView:(TextViewWithDataDetectorWorkaround *)textView willOpenURL:(NSURL *)URL;
// track when long press a link, to show the menu controller
- (void)textView:(TextViewWithDataDetectorWorkaround *)textView didLongPressLinkWithGestureRecognizer:(UILongPressGestureRecognizer *)longPress;
@end



/// This UITextView subclass works around a bug in Data Detectors.
///
/// The bug was filed as radar://problem/15512848.
/// We opened an Apple Deveoper Technical Support (DTS) ticket # 601232848 and they suggested this workaround until UIKit fixes the underlying bug.
///
@interface TextViewWithDataDetectorWorkaround : UITextView
@property (weak, nonatomic) id<TextViewInteractionDelegate> textViewInteractionDelegate;
@end
