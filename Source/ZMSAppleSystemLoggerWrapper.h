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

NS_ASSUME_NONNULL_BEGIN


/// Log levels
typedef NS_ENUM(int, ZMASLLevel) {
    ZMASLLevelEmergency = 0,
    ZMASLLevelAlert = 1,
    ZMASLLevelCritical = 2,
    ZMASLLevelError = 3,
    ZMASLLevelWarning = 4,
    ZMASLLevelNotice = 5,
    ZMASLLevelInfo = 6,
    ZMASLLevelDebug = 7,
};



/// Simple wrapper around asl_object_t with ASL_TYPE_MSG
@interface ZMSASLMessage : NSObject

@property (nonatomic, copy, readonly) NSString *messageText;
@property (nonatomic, readonly) ZMASLLevel level;

- (instancetype)initWithMessage:(NSString *)message level:(ZMASLLevel)level;

@end



/// Simple wrapper around asl_object_t with ASL_TYPE_CLIENT
@interface ZMSASLClient : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier facility:(nullable NSString *)facility;

- (void)sendMessage:(ZMSASLMessage *)message;

@end

NS_ASSUME_NONNULL_END
