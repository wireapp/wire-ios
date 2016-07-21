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


#import "AvatarImageView.h"

#import <PureLayout/PureLayout.h>

@interface AvatarImageView ()

@property (nonatomic) UIView *containerView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *initials;


@property (nonatomic) NSLayoutConstraint *initialsVerticalAlignmentConstraint;
@property (nonatomic) BOOL initialConstraintsCreated;

@end

@implementation AvatarImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)setup
{
    [self createContainerView];
    [self createImageView];
    [self createInitials];
    [self setNeedsUpdateConstraints];
}

- (void)createContainerView
{
    self.containerView = [[UIView alloc] initForAutoLayout];
    self.containerView.clipsToBounds = YES;
    [self addSubview:self.containerView];
}

- (void)createImageView
{
    self.imageView = [[UIImageView alloc] initForAutoLayout];
    self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
    self.imageView.opaque = NO;
    [self.containerView addSubview:self.imageView];
}

- (void)createInitials
{
    self.initials = [[UILabel alloc] initForAutoLayout];
    self.initials.opaque = NO;
    [self.containerView addSubview:self.initials];
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        [self.containerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.initials autoCenterInSuperview];

        self.initialConstraintsCreated = YES;
    }

    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.containerView.layer.cornerRadius = self.bounds.size.width / 2;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    self.containerView.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth
{
    return self.containerView.layer.borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    self.containerView.layer.borderColor = borderColor.CGColor;
}

- (UIColor *)borderColor
{
    return [UIColor colorWithCGColor:self.containerView.layer.borderColor];
}

@end
