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


#import "CommonConnectionsViewController.h"
#import "CommonConnectionsView.h"

#import "WAZUIMagicIOS.h"
#import "UIFont+MagicAccess.h"
#import "UIColor+MagicAccess.h"
#import "NSString+WAZUIMagic.h"
#import "zmessaging+iOS.h"
#import <zmessaging/ZMBareUser+UserSession.h>
@import WireExtensionComponents;

@interface CommonConnectionsViewController () <ZMCommonContactsSearchDelegate>
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) CommonConnectionsView *avatarsContainer;
@property (nonatomic, weak)   id<ZMCommonContactsSearchToken> recentSearchToken;
@end

@implementation CommonConnectionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createViews];
    [self createConstraints];
}

- (void)createViews
{
    self.headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabel.backgroundColor = [UIColor clearColor];
    self.headerLabel.text = [NSLocalizedString(@"profile_other.common_connections", @"") transformStringWithMagicKey:@"common_connections.header_transform"];
    self.headerLabel.hidden = YES;
    [self.view addSubview:self.headerLabel];
    
    self.avatarsContainer = [[CommonConnectionsView alloc] initWithFrame:CGRectZero];
    self.avatarsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarsContainer.didSelectUser = self.didSelectUser;
    [self.view addSubview:self.avatarsContainer];
}

- (void)createConstraints
{
    [self.headerLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.headerLabel addConstraintForAligningHorizontallyWithView:self.view];
    [self.headerLabel addConstraintForTopMargin:0 relativeToView:self.view];

    [self.avatarsContainer addConstraintForLeftMargin:[WAZUIMagic floatForIdentifier:@"common_connections.avatars_left_margin"] relativeToView:self.view];
    [self.avatarsContainer addConstraintForRightMargin:[WAZUIMagic floatForIdentifier:@"common_connections.avatars_right_margin"] relativeToView:self.view];
    [self.avatarsContainer addConstraintForBottomMargin:0 relativeToView:self.view];
    [self.avatarsContainer addConstraintForAligningTopToBottomOfView:self.headerLabel distance:[WAZUIMagic floatForIdentifier:@"common_connections.avatars_top_margin"]];
}

#pragma mark - Accessors

- (void)setUser:(id<ZMBareUser, ZMSearchableUser>)bareUser
{
    if (_user != bareUser) {
        _user = bareUser;
        self.recentSearchToken = [bareUser searchCommonContactsInUserSession:[ZMUserSession sharedSession] withDelegate:self];
    }
}

- (void)setDidSelectUser:(void (^)(ZMUser *))didSelectUser
{
    _didSelectUser = didSelectUser;
    if (self.avatarsContainer != nil) {
        self.avatarsContainer.didSelectUser = self.didSelectUser;
    }
}

#pragma mark - ZMCommonContactsSearchDelegate

- (void)didReceiveCommonContactsUsers:(NSOrderedSet *)users forSearchToken:(id<ZMCommonContactsSearchToken>)searchToken
{
    if (searchToken == self.recentSearchToken) {
        self.avatarsContainer.users = users;
        self.headerLabel.hidden = (users.count == 0);
    }
}

@end
