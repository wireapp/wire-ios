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

@class ZMUser;

@interface AddressBookHelper : NSObject

@property (nonatomic, assign) BOOL addressBookWasUploaded;
@property (nonatomic, assign) BOOL addressBookUploadWasPostponed;
@property (nonatomic, assign) BOOL addressBookUploadWasProposed;

+ (instancetype)sharedHelper;

- (BOOL)isAddressBookSupported;

/// This is the preferable way to upload the addressbook to the backend.
/// This upload method respects the last AB upload time and will only upload the AB in case the last upload time has been passed. See the @c forceUploadAddressBook method in case you want to push the AB in anycase
- (void)uploadAddressBook;

/// Enforce the AB upload and dont respect the last AB upload time. Use this method only during the registration
- (void)forceUploadAddressBook;

- (BOOL)isAddressBookAccessUnknown;

- (BOOL)isAddressBookAccessGranted;

- (BOOL)isAddressBookAccessDisabled;

- (void)requestPermissions:(void(^)(BOOL success))callback;

@end
