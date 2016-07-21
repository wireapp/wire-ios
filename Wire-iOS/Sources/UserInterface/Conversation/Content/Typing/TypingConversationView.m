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


//ui
#import "TypingConversationView.h"
#import "TypingUserView.h"
#import <PureLayout.h>
#import "UIView+MTAnimation.h"
#import "zmessaging+iOS.h"

@interface TypingConversationView ()
@property (nonatomic, assign) BOOL initialLayoutDone;

@property (nonatomic, strong) NSLayoutConstraint *currentUserViewTopOffset;
@property (nonatomic, strong) TypingUserView *currentUserView;
@end

@implementation TypingConversationView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {

        _users = [NSSet set];
        _initialLayoutDone = NO;

        self.currentUserView = [[TypingUserView alloc] initForAutoLayout];
        self.currentUserView.alpha = 0.0f;
        [self addSubview:self.currentUserView];
        //cosmetic
        self.backgroundColor = [UIColor clearColor];

        [self setNeedsUpdateConstraints];
        [self layoutIfNeeded];
    }
    
    return self;
}

- (void)updateConstraints
{
    if (! self.initialLayoutDone) {
        self.initialLayoutDone = YES;

        [self.currentUserView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
        [self.currentUserView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
        self.currentUserViewTopOffset = [self.currentUserView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
        [self.currentUserView autoAlignAxis:ALAxisVertical toSameAxisOfView:self];
    }
    
    [super updateConstraints];
}

- (void)setUsers:(NSSet *)users
{
    NSMutableSet *notChangedUsersSet = [_users mutableCopy];
    NSMutableSet *removedUsersSet = [_users mutableCopy];
    NSMutableSet *addedUsersSet = [users mutableCopy];
    
    [notChangedUsersSet intersectSet:users];
    [removedUsersSet minusSet:notChangedUsersSet];
    [addedUsersSet minusSet:notChangedUsersSet];
    
    _users = users;
    
    for (ZMUser *removedUser in removedUsersSet) {
        [self removeUserImageViewForUser:removedUser animated:self.window != nil];
    }

    for (ZMUser *addedUser in addedUsersSet) {
        [self addUserImageViewForUser:addedUser animated:self.window != nil];
    }
}

- (void)addUserImageViewForUser:(ZMUser *)addUser animated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(typingConversationView:willShowUsers:)]) {
        [self.delegate typingConversationView:self willShowUsers:[NSSet setWithObject:addUser]];
    }

    self.currentUserView.user = addUser;

    if (animated) {
        self.currentUserView.alpha = 0.0f;
        self.currentUserViewTopOffset.constant = 8.0f;
        [self layoutIfNeeded];

        [UIView mt_animateWithViews:@[self.currentUserView]
                           duration:0.55f
                     timingFunction:MTTimingFunctionEaseOutExpo
                         animations:^{
                             self.currentUserViewTopOffset.constant = 0.0f;
                             [self layoutIfNeeded];
                             self.currentUserView.alpha = 1.0f;
                         }];
    }
    else {
        self.currentUserViewTopOffset.constant = 0.0f;
        [self layoutIfNeeded];
        self.currentUserView.alpha = 1.0f;
    }
}

- (void)removeUserImageViewForUser:(ZMUser *)removeUser animated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(typingConversationView:willHideUsers:)]) {
        [self.delegate typingConversationView:self willHideUsers:[NSSet setWithObject:removeUser]];
    }

    if (animated) {
        [UIView mt_animateWithViews:@[self.currentUserView]
                           duration:0.35f
                     timingFunction:MTTimingFunctionEaseOutQuart
                         animations:^{
                             self.currentUserView.alpha = 0.0f;
                         }
                         completion:^{
                             self.currentUserView.user = nil;
                         }];
    }
    else {
        self.currentUserView.user = nil;
    }
}

@end

