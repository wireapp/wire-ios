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


#import <Foundation/Foundation.h>
#import "PeopleInputController.h"

@class PeopleSelection;
@protocol ZMBareUser;

@protocol PeopleSelectionDelegate <NSObject>
@optional
- (void)selectedUsersUpdated:(PeopleSelection *)selection;
- (void)peopleSelection:(PeopleSelection *)selection didSelectUsers:(NSSet *)users;
- (void)peopleSelection:(PeopleSelection *)selection didDeselectUsers:(NSSet *)users;
@end

@interface PeopleSelection : NSObject <PeopleInputControllerSelectionDelegate>
@property (nonatomic, readonly) NSSet *selectedUsers;
@property (nonatomic, weak) PeopleInputController *peopleInputController;
@property (nonatomic, weak) id<PeopleSelectionDelegate> delegate;

- (void)addUserToSelectedResults:(ZMUser *)user;
- (void)removeUserFromSelectedResults:(ZMUser *)user;
@end
