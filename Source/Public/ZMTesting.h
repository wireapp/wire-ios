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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#import <Foundation/Foundation.h>

//! Project version number for ZMTesting.
FOUNDATION_EXPORT double ZMTestingVersionNumber;

//! Project version string for ZMTesting.
FOUNDATION_EXPORT const unsigned char ZMTestingVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ZMTesting/PublicHeader.h>

#import <ZMTesting/ZMTBaseTest.h>
#import <ZMTesting/XCTestCase+Helpers.h>
#import <ZMTesting/ZMTFailureRecorder.h>
#import <ZMTesting/ZMTAsserts.h>
#import <ZMTesting/NSData+ZMTesting.h>
#import <ZMTesting/NSOperationQueue+ZMTesting.h>
#import <ZMTesting/ZMTImageComparator.h>
#import <ZMTesting/NSUUID+ZMTesting.h>
#import <ZMTesting/ZMMockManagedObjectContextFactory.h>
#import <ZMTesting/ZMMockEntity.h>
#import <ZMTesting/ZMMockEntity2.h>
