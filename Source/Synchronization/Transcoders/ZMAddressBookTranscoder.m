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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


@import ZMCSystem;
@import ZMTransport;

#import "ZMAddressBookTranscoder.h"

#import "ZMAddressBookSync.h"
#import "ZMEmptyAddressBookSync.h"
#import "ZMAddressBook.h"

@interface ZMAddressBookTranscoder ()

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                             addressBookSync:(ZMAddressBookSync *)addressBookSync
                        emptyAddressBookSync:(ZMEmptyAddressBookSync *)emptyAddressBookSync NS_DESIGNATED_INITIALIZER;

@property (nonatomic) ZMAddressBookSync *addressBookSync;
@property (nonatomic) ZMEmptyAddressBookSync *emptyAddresBookSync;

@end


@implementation ZMAddressBookTranscoder

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
{
    return [self initWithManagedObjectContext:moc addressBookSync:nil emptyAddressBookSync:nil];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                             addressBookSync:(ZMAddressBookSync *)addressBookSync
                        emptyAddressBookSync:(ZMEmptyAddressBookSync *)emptyAddressBookSync;
{
    self = [super initWithManagedObjectContext:moc];
    if (self != nil) {
        self.addressBookSync = addressBookSync ?: [[ZMAddressBookSync alloc] initWithManagedObjectContext:moc];
        self.emptyAddresBookSync = emptyAddressBookSync ?:[[ZMEmptyAddressBookSync alloc] initWithManagedObjectContext:moc];
    }
    return self;
}


- (BOOL)isSlowSyncDone
{
    return YES;
}

- (void)tearDown
{
    [self.emptyAddresBookSync tearDown];
    self.emptyAddresBookSync = nil;
    [self.addressBookSync tearDown];
    self.addressBookSync = nil;
    [super tearDown];
}

- (NSArray *)contextChangeTrackers
{
    return [NSArray array];
}

- (void)setNeedsSlowSync
{
    // no op
}

- (void)processEvents:(__unused NSArray<ZMUpdateEvent *> *)events
           liveEvents:(__unused BOOL)liveEvents
       prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult
{
    // no op
}

- (NSArray *)requestGenerators;
{
    return @[self.addressBookSync, self.emptyAddresBookSync];
}

@end
