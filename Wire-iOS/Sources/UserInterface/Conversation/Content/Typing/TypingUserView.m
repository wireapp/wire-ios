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


#import "TypingUserView.h"
#import "zmessaging+iOS.h"
#import "UserImageView.h"
#import <PureLayout.h>
#import "UIView+Borders.h"
#import "WAZUIMagicIOS.h"
#import "UIView+MTAnimation.h"

@interface TypingUserView ()

@property (nonatomic, assign) BOOL initialLayoutDone;
@property (nonatomic, strong) UserImageView *userImageView;

@end

@implementation TypingUserView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _initialLayoutDone = NO;
        //cosmetic
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)setUser:(ZMUser *)user
{
    if (_user != user){
        _user = user;
        
        if (_user == nil) {
            [self.userImageView removeFromSuperview];
            self.userImageView = nil;
            self.initialLayoutDone = NO;

            [self stopPulsing];
        }
        else {
            self.userImageView = [[UserImageView alloc] initWithMagicPrefix:@"content.author_image"];
            self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
            self.userImageView.borderWidth = 0.0f;
                        
            [self addSubview:self.userImageView];
            
            self.userImageView.user = user;

            [self startPulsing];
        }
        [self setNeedsUpdateConstraints];
    }
}

- (void)updateConstraints
{
    if (!self.initialLayoutDone && self.userImageView != nil){
        CGFloat authorImageDiameter = [WAZUIMagic floatForIdentifier:@"content.sender_image_tile_diameter"];
        
        [self.userImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.userImageView autoSetDimensionsToSize:CGSizeMake(authorImageDiameter, authorImageDiameter)];
        
        self.initialLayoutDone = YES;
    }
    
    [super updateConstraints];
}

- (void)startPulsing
{
    [self animateSignlePulse];
}

- (void)stopPulsing
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateSignlePulse) object:nil];
}

- (void)animateSignlePulse
{
    [UIView mt_animateWithViews:@[self]
                       duration:0.35f
                 timingFunction:kMTEaseInExpo
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(1.16f, 1.16f);
                     }
                     completion:^() {
                         [UIView mt_animateWithViews:@[self]
                                            duration:0.35f
                                      timingFunction:kMTEaseOutExpo
                                          animations:^{
                                              self.transform = CGAffineTransformMakeScale(1.f, 1.f);
                                          }];

                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             [UIView mt_animateWithViews:@[self]
                                                duration:0.35f
                                          timingFunction:kMTEaseInExpo
                                              animations:^{
                                                  self.transform = CGAffineTransformMakeScale(1.16f, 1.16f);
                                              }
                                              completion:^() {
                                                  [UIView mt_animateWithViews:@[self]
                                                                     duration:0.35f
                                                               timingFunction:kMTEaseOutExpo
                                                                   animations:^{
                                                                       self.transform = CGAffineTransformMakeScale(1.f, 1.f);
                                                                   }
                                                                   completion:^{
                                                                       if (self.user != nil) {
                                                                           NSTimeInterval delay = 2.2f + (rand() % 56) * 0.01f;
                                                                           [self performSelector:@selector(animateSignlePulse) withObject:nil afterDelay:delay];
                                                                       }
                                                                   }];
                                              }];
                         });

                     }];
}

@end
