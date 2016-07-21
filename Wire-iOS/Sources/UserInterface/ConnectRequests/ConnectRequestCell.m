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


#import "ConnectRequestCell.h"
#import "IncomingConnectRequestView.h"
#import "UserImageView.h"
#import "WAZUIMagic.h"

#import <PureLayout/PureLayout.h>


#import "zmessaging+iOS.h"

@interface ConnectRequestCell ()
@property (nonatomic) UserImageView *userImageView;
@end

@implementation ConnectRequestCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        self.incomingConnectRequestView = [[IncomingConnectRequestView alloc] init];
        self.incomingConnectRequestView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.incomingConnectRequestView];

        [self.incomingConnectRequestView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.incomingConnectRequestView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.incomingConnectRequestView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
            [self.incomingConnectRequestView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-48];
        }];
        [self.incomingConnectRequestView autoSetDimension:ALDimensionWidth toSize:420 relation:NSLayoutRelationLessThanOrEqual];
    }
    return self;
}

- (void)setUser:(ZMUser *)user
{
    _user = user;
    self.incomingConnectRequestView.user = user;
}

- (void)setAcceptBlock:(void (^)())acceptBlock
{
    _acceptBlock = [acceptBlock copy];
    self.incomingConnectRequestView.acceptBlock = self.acceptBlock;
}

- (void)setIgnoreBlock:(void (^)())ignoreBlock
{
    _ignoreBlock = [ignoreBlock copy];
    self.incomingConnectRequestView.ignoreBlock = self.ignoreBlock;
}

@end
