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


#import "MoreConnectionsButton.h"
#import "WAZUIMagicIOS.h"
#import "UIFont+MagicAccess.h"
#import "NSString+WAZUIMagic.h"
#import "NSLayoutConstraint+Helpers.h"



@interface MoreConnectionsButton ()
@property (nonatomic, strong) UILabel *moreCountLabel;
@end

@implementation MoreConnectionsButton

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
    self.moreCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.moreCountLabel.userInteractionEnabled = NO;
    self.moreCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.moreCountLabel.font = [UIFont fontWithMagicIdentifier:@"common_connections.connection.more_font"];
    self.moreCountLabel.textAlignment = NSTextAlignmentCenter;
    self.moreCountLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.moreCountLabel];
}

- (void)setupConstraints
{
    [self.moreCountLabel addConstraintForTopMargin:0 relativeToView:self];
    [self.moreCountLabel addConstraintForAligningHorizontallyWithView:self];
    [self.moreCountLabel addConstraintsForSize:self.class.countLabelSize];
}

- (void)setMoreUsersCount:(NSUInteger)moreUsersCount
{
    _moreUsersCount = moreUsersCount;
    self.moreCountLabel.text = [NSString stringWithFormat:@"+%lu", (unsigned long)self.moreUsersCount];
}

+ (CGSize)countLabelSize
{
    NSArray *avatarSize = [WAZUIMagic sharedMagic][@"common_connections.connection.avatar_size"];
    return CGSizeMake([avatarSize[0] floatValue], [avatarSize[1] floatValue]);
}

+ (CGSize)labelSize
{
    NSArray *labelSize = [WAZUIMagic sharedMagic][@"common_connections.connection.label_size"];
    return CGSizeMake([labelSize[0] floatValue], [labelSize[1] floatValue]);
}

@end
