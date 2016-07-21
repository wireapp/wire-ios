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


#import "CommonConnectionButton.h"
#import "UserImageView.h"
#import "WAZUIMagicIOS.h"
#import "UIFont+MagicAccess.h"
#import "NSString+WAZUIMagic.h"

#import "zmessaging+iOS.h"
#import "UIView+Borders.h"

@interface CommonConnectionButton ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UserImageView *userImageView;
@end

@implementation CommonConnectionButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (nil != self) {
        [self setupSubviews];
        [self setupConstraints];
    }
    return self;
}

- (void)setupSubviews
{
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.nameLabel.userInteractionEnabled = NO;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.backgroundColor = [UIColor clearColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.nameLabel];

    self.userImageView = [[UserImageView alloc] initWithMagicPrefix:@"people_picker"];
    self.userImageView.userInteractionEnabled = NO;
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.userImageView];
}

- (void)setupConstraints
{
    [self.userImageView addConstraintForTopMargin:0 relativeToView:self];
    [self.userImageView addConstraintsForSize:self.class.avatarSize];
    [self.userImageView addConstraintForAligningHorizontallyWithView:self];

    [self.nameLabel addConstraintForLeftMargin:0 relativeToView:self];
    [self.nameLabel addConstraintForRightMargin:0 relativeToView:self];
    [self.nameLabel addConstraintForAligningTopToBottomOfView:self.userImageView distance:0];
    [self.nameLabel addConstraintForBottomMargin:0 relativeToView:self];
    [self.nameLabel addConstraintsForSize:self.class.labelSize];
}

- (void)setUser:(ZMUser *)user
{
    if (_user != user) {
        _user = user;

        if (self.user != nil) {
            self.userImageView.user = self.user;
            self.nameLabel.text = [self.user.displayName transformStringWithMagicKey:@"common_connections.connection.name_transform"];
        }
    }
}

+ (CGSize)labelSize
{
    NSArray *labelSize = [WAZUIMagic sharedMagic][@"common_connections.connection.label_size"];
    return CGSizeMake([labelSize[0] floatValue], [labelSize[1] floatValue]);
}

+ (CGSize)avatarSize
{
    NSArray *avatarSize = [WAZUIMagic sharedMagic][@"common_connections.connection.avatar_size"];
    return CGSizeMake([avatarSize[0] floatValue], [avatarSize[1] floatValue]);
}

+ (CGSize)itemSize
{
    return CGSizeMake([self labelSize].width, [self labelSize].height + [self avatarSize].height);
}

@end
