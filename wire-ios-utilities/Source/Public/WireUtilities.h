//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

//! Project version number for WireUtilities.
FOUNDATION_EXPORT double WireUtilitiesVersionNumber;

//! Project version string for WireUtilities.
FOUNDATION_EXPORT const unsigned char WireUtilitiesVersionString[];

#import <WireUtilities/NSData+ZMAdditions.h>
#import <WireUtilities/NSData+ZMSCrypto.h>
#import <WireUtilities/NSOperationQueue+Helpers.h>
#import <WireUtilities/NSUUID+Data.h>
#import <WireUtilities/ZMFunctional.h>
#import <WireUtilities/ZMTimer.h>
#import <WireUtilities/NSUserDefaults+SharedUserDefaults.h>
#import <WireUtilities/NSLocale+Internal.h>
#import <WireUtilities/ZMMobileProvisionParser.h>
#import <WireUtilities/NSString+Normalization.h>
#import <WireUtilities/ZMEncodedNSUUIDWithTimestamp.h>
#import <WireUtilities/ZMAccentColor.h>
#import <WireUtilities/ZMAtomicInteger.h>
#import <WireUtilities/ZMObjectValidationError.h>
