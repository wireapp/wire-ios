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
#import <dispatch/dispatch.h>
@import WireSystem;



@protocol ZMNetworkSocketDelegate;



@interface ZMNetworkSocket : NSObject

- (instancetype)initWithURL:(NSURL *)URL delegate:(id<ZMNetworkSocketDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue group:(ZMSDispatchGroup *)group ZM_NON_NULL(1, 2, 3, 4);

@property (nonatomic, readonly, weak) id<ZMNetworkSocketDelegate> delegate;

- (void)writeDataToNetwork:(dispatch_data_t)data;
- (void)open;
- (void)close;

@end



@protocol ZMNetworkSocketDelegate <NSObject>

- (void)networkSocketDidOpen:(ZMNetworkSocket *)socket;
- (void)networkSocket:(ZMNetworkSocket *)socket didReceiveData:(dispatch_data_t)data;
- (void)networkSocketDidClose:(ZMNetworkSocket *)socket;

@end
