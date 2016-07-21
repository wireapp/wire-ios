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


@import WireExtensionComponents;

#import "InviteContactsViewController.h"
#import "ContactsViewController+Private.h"
#import "ContactsDataSource.h"
#import "ZClientViewController.h"
#import "TokenField.h"
#import "ContactsCell.h"
#import "zmessaging+iOS.h"

@interface InviteContactsViewController () <ContactsViewControllerDelegate, ContactsViewControllerContentDelegate>
@end

@implementation InviteContactsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        ZMSearchRequest *searchRequest = [ZMSearchRequest new];
        searchRequest.includeAddressBookContacts = YES;
        searchRequest.includeContacts = YES;
        
        self.colorSchemeVariant = ColorSchemeVariantDark;
        self.delegate = self;
        self.contentDelegate = self;
        self.dataSource = [[ContactsDataSource alloc] initWithSearchRequest:searchRequest];
        
        self.title = NSLocalizedString(@"contacts_ui.title", @"");
    }
    
    return self;
}

- (BOOL)sharingContactsRequired
{
    return YES;
}

#pragma mark - ContactsViewControllerDelegate

- (void)contactsViewControllerDidCancel:(ContactsViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactsViewControllerDidNotShareContacts:(ContactsViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ContactsViewControllerContentDelegate

- (BOOL)contactsViewController:(ContactsViewController *)controller shouldDisplayActionButtonForUser:(ZMSearchUser *)user
{
    return YES;
}

- (NSArray *)actionButtonTitlesForContactsViewController:(ContactsViewController *)controller
{
    return @[
             NSLocalizedString(@"contacts_ui.action_button.open", @""),
             NSLocalizedString(@"contacts_ui.action_button.invite", @""),
             ];
}

- (NSUInteger)contactsViewController:(ContactsViewController *)controller actionButtonTitleIndexForUser:(ZMSearchUser *)user
{
    if (user.isConnected || (user.user.isPendingApprovalBySelfUser && ! user.user.isIgnored)) {
        return 0;
    } else {
        return 1;
    }
}

- (void)contactsViewController:(ContactsViewController *)controller actionButton:(UIButton *)actionButton pressedForUser:(ZMSearchUser *)user
{
    if (user.isConnected) {
        [self dismissViewControllerAnimated:YES completion:^{
            [[ZClientViewController sharedZClientViewController] selectConversation:user.user.oneToOneConversation
                                                                        focusOnView:YES
                                                                           animated:YES];
        }];
    } else if (user.user.isPendingApprovalBySelfUser && ! user.user.isIgnored) {
        [self dismissViewControllerAnimated:YES completion:^{
            [[ZClientViewController sharedZClientViewController] selectIncomingContactRequestsAndFocusOnView:YES];
        }];
    } else {
        [self inviteContact:user.contact fromView:actionButton];
    }
}

- (void)contactsViewController:(ContactsViewController *)controller didSelectCell:(ContactsCell *)cell forUser:(ZMSearchUser *)user
{
    if (! user.isConnected) {
        [self inviteContact:user.contact fromView:cell.contentView];
    }
}

@end
