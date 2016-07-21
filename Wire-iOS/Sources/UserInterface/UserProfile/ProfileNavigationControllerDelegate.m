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


#import "ProfileNavigationControllerDelegate.h"
#import "ZoomTransition.h"
#import "UIViewController+WR_Additions.h"

@implementation ProfileNavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (navigationController.wr_isInsidePopoverPresentation) {
        return nil;
    }
        
    BOOL reversed = operation == UINavigationControllerOperationPop;
    CGPoint interactionPoint = CGPointMake(self.tapLocation.x / fromVC.view.bounds.size.width, self.tapLocation.y / fromVC.view.bounds.size.height);
    return [[ZoomTransition alloc] initWithInteractionPoint:interactionPoint reversed:reversed];
}

@end
