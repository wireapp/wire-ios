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


#import "ProfileSelfCameraTransition.h"
#import "UIView+WR_ExtendedBlockAnimations.h"



@interface ProfileSelfCameraTransition ()

@property (nonatomic, weak) UIView *bottomBarView;
@property (nonatomic) BOOL reverse;

@end



@implementation ProfileSelfCameraTransition

- (instancetype)initWithBottomBarView:(UIView *)bottomBarView reverse:(BOOL)reverse
{
    self = [super init];
    
    if (self) {
        self.bottomBarView = bottomBarView;
        self.reverse = reverse;
    }
    
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.90f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    toView.frame = [transitionContext finalFrameForViewController:[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    [containerView addSubview:toView];
    
    if (! [transitionContext isAnimated]) {
        [transitionContext completeTransition:YES];
        return;
    }
    
    [toView layoutIfNeeded];
    
    CGAffineTransform offscreenBar = CGAffineTransformMakeTranslation(0, containerView.bounds.size.height - self.bottomBarView.frame.origin.y);
    
    if (self.reverse) {
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseInExpo duration:0.35 delay:0 animations:^{
            self.bottomBarView.transform = offscreenBar;
        } completion:^(BOOL finished) {
            [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutQuart duration:0.55 delay:0 animations:^{
                toViewController.view.alpha = 1;
                fromViewController.view.alpha = 0;
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }];
    } else {
        toViewController.view.alpha = 0;
        self.bottomBarView.transform = offscreenBar;
        
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutQuart duration:0.35 delay:0 animations:^{
            fromViewController.view.alpha = 0;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.55 delay:0 animations:^{
                self.bottomBarView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }];
    }
}

@end
