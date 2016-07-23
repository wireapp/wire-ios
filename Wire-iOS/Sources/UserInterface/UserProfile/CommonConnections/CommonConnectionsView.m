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

#import "CommonConnectionsView.h"
#import "CommonConnectionButton.h"
#import "MoreConnectionsButton.h"
#import "WAZUIMagicIOS.h"

#import "UIView+Borders.h"
@import WireExtensionComponents;

@interface CommonConnectionsView ()
@property (nonatomic, assign) CGRect previousLayoutBounds;
@property (nonatomic, strong) NSArray *connectionViews;
@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) NSMutableSet *queuedConnectionViews;
@property (nonatomic, strong) MoreConnectionsButton *moreConnectionsButton;
@end

@implementation CommonConnectionsView

#pragma mark - Overloaded methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (nil != self) {
        self.queuedConnectionViews = [NSMutableSet set];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];

        self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
        self.containerView.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.containerView];
        [self.containerView addConstraintForTopMargin:0 relativeToView:self];
        [self.containerView addConstraintForBottomMargin:0 relativeToView:self];
        [self.containerView addConstraintForAligningHorizontallyWithView:self];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (! CGRectEqualToRect(self.previousLayoutBounds, self.bounds)) {
        self.previousLayoutBounds = self.bounds;

        [self setupSubviews];
    }
}

#pragma mark - Custom methods

- (void)setupSubviews
{
    // first remove old views
    for (CommonConnectionButton *btt in self.connectionViews) {
        [btt removeFromSuperview];
        btt.user = nil;
        [self enqueueButton:btt];
    }
    [self.moreConnectionsButton removeFromSuperview];
    self.connectionViews = nil;

    // prepare loop
    NSMutableArray *newConnectionViews = [NSMutableArray array];
    CGFloat currentOffset = 0.0f;
    CGFloat totalSpan = self.bounds.size.width;
    CGFloat offset = [WAZUIMagic floatForIdentifier:@"common_connections.avatars_horizontal_offset"];
    CGSize itemSize = [CommonConnectionButton itemSize];

    UIView *prevView = self;

    // do loop and create layout
    for (NSUInteger userIndex = 0; userIndex < self.users.count; userIndex++) {
        ZMUser *user = self.users[userIndex];

        if ((currentOffset + itemSize.width) > totalSpan) { // next item does not fit

            break;
        }
        else { // next item fits
            if ((currentOffset + itemSize.width * 2) > totalSpan && userIndex != self.users.count - 1) {
                // two items does not fit, and we have more users left
                self.moreConnectionsButton.moreUsersCount = self.users.count - userIndex;
                currentOffset+= itemSize.width + offset;
                [self.containerView addSubview:self.moreConnectionsButton];
                if (prevView == self) {
                    [self.moreConnectionsButton addConstraintForAligningLeftToLeftOfView:self.containerView distance:0];
                }
                else {
                    [self.moreConnectionsButton addConstraintForAligningLeftToRightOfView:prevView distance:offset];
                }
                [self.moreConnectionsButton addConstraintForTopMargin:0 relativeToView:self.containerView];
                [self.moreConnectionsButton addConstraintForBottomMargin:0 relativeToView:self.containerView];
                prevView = self.moreConnectionsButton;
            }
            else {
                CommonConnectionButton *button = [self dequeueButton];
                button.user = user;

                currentOffset+= itemSize.width + offset;

                [self.containerView addSubview:button];
                if (prevView == self) {
                    [button addConstraintForAligningLeftToLeftOfView:self.containerView distance:0];
                }
                else {
                    [button addConstraintForAligningLeftToRightOfView:prevView distance:offset];
                }
                [button addConstraintForTopMargin:0 relativeToView:self.containerView];
                [button addConstraintForBottomMargin:0 relativeToView:self.containerView];
                prevView = button;
                [newConnectionViews addObject:button];
            }
        }
    }

    if (prevView != self) {
        [prevView addConstraintForAligningRightToRightOfView:self.containerView distance:0];
    }

    self.connectionViews = newConnectionViews;
}

- (void)enqueueButton:(CommonConnectionButton *)button
{
    [self.queuedConnectionViews addObject:button];
}

- (CommonConnectionButton *)dequeueButton
{
    if (self.queuedConnectionViews.count == 0) {
        CommonConnectionButton *new = [[CommonConnectionButton alloc] initWithFrame:CGRectZero];
        new.translatesAutoresizingMaskIntoConstraints = NO;
        // CommonConnectionButton setup
        [new addTarget:self action:@selector(didSelectUser:) forControlEvents:UIControlEventTouchUpInside];
        return new;
    }
    else {
        CommonConnectionButton *btt = self.queuedConnectionViews.anyObject;
        [self.queuedConnectionViews removeObject:btt];
        return btt;
    }
}

- (MoreConnectionsButton *)moreConnectionsButton
{
    if (_moreConnectionsButton == nil) {
        MoreConnectionsButton *button = [[MoreConnectionsButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        //MoreConnectionsButton setup
        _moreConnectionsButton = button;
    }

    return _moreConnectionsButton;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, [CommonConnectionButton itemSize].height);
}

#pragma mark - Callbacks

- (void)didSelectUser:(CommonConnectionButton *)button
{
    if (self.didSelectUser != nil) {
        self.didSelectUser(button.user);
    }
}

- (void)didReceiveMemoryWarning
{
    self.queuedConnectionViews = [NSMutableSet set];
}

#pragma mark - Setters

- (void)setUsers:(NSOrderedSet *)users
{
    if (_users != users) {
        _users = users;

        [self setupSubviews];
    }
}

@end
