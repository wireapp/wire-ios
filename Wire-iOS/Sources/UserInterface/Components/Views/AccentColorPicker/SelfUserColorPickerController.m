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


#import "SelfUserColorPickerController.h"

#import "ColorPickerController+Internal.h"
#import "zmessaging+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "IdentifiableColor.h"



@interface SelfUserColorPickerController () <ZMUserObserver>

@property (nonatomic) id <ZMUserObserverOpaqueToken> userObserverToken;

@end

@implementation SelfUserColorPickerController

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
    if (change.user == [ZMUser selfUser] && change.accentColorValueChanged) {
        // Don’t do anything if the user is currently changing the color on this device
        if (self.panner.state == UIGestureRecognizerStateChanged) {
            return;
        }
        
        IdentifiableColor *color = [self.colors wr_identifiableColorByTag:[UIColor indexedAccentColor]];
        self.previewColor = color;
        [self animateKnobToColor:self.previewColor];
    }
}

@end
