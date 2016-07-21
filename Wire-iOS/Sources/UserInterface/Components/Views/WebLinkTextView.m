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


// This subclass is used for the legal text in the Welcome screen and the reset password text in the login screen
// Purpose of this class is to reduce the amount of duplicate code to set the default properties of this NSTextView. On the Mac client we are using something similar to also stop the user from being able to select the text (selection property needs to be enabled to make the NSLinkAttribute work on the string). We may want to add this in the future here as well

#import "WebLinkTextView.h"



@implementation WebLinkTextView

- (id)init
{
    self = [super init];
    if (self) {
        [self setupWebLinkTextView];
    }
    return self;
}

- (void)setupWebLinkTextView
{
    [self setSelectable:YES];
    [self setEditable:NO];
    [self setScrollEnabled:NO];
    [self setBounces:NO];
    self.backgroundColor = [UIColor clearColor];
    [self setTextContainerInset:UIEdgeInsetsMake(0, - 4, 0, 0)];
}

@end

