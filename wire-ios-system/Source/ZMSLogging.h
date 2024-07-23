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
#import <WireSystem/ZMSAsserts.h>

/// Log levels
typedef NS_CLOSED_ENUM(int8_t, ZMLogLevel) {
    ZMLogLevelPublic = 0,
    ZMLogLevelError,
    ZMLogLevelWarn,
    ZMLogLevelInfo,
    ZMLogLevelDebug,
};

/**
 
 Logging
 
 
 This is for zmessaging logging.
 
 
 How to use:
 
 At the top of the file define the log level like so:
 
 @code
 static NSString* ZMLogTag ZM_UNUSED = "Network";
 @endcode
 
 The @c ZMLogError() etc. then work just like @c NSLog() does.
 
 
 You can set a (symbolic) breakpoint at ZMLogDebugger to stop automatically when a warning or error level message is logged.
 
 **/
#define ZMLogPublic(format, ...) ZMLogWithLevelAndTag(ZMLogLevelPublic, ZMLogTag, format, ##__VA_ARGS__)
#define ZMLogError(format, ...) ZMLogWithLevel(ZMLogLevelError, format, ##__VA_ARGS__)
#define ZMLogWarn(format, ...) ZMLogWithLevel(ZMLogLevelWarn, format, ##__VA_ARGS__)
#define ZMLogInfo(format, ...) ZMLogWithLevelAndTag(ZMLogLevelInfo, ZMLogTag, format, ##__VA_ARGS__)
#define ZMLogDebug(format, ...) ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMLogTag, format, ##__VA_ARGS__)

#define ZMLogWithLevelAndTag(level, tag, format, ...) \
    do { \
        NSString *message = [[NSString alloc] initWithFormat:format, ##__VA_ARGS__]; \
        [ZMSLog logWithLevel:level message:^NSString * _Nonnull { \
            return message; \
        } tag:tag file:[NSString stringWithUTF8String:__FILE__] line:(NSUInteger)__LINE__]; \
    } while (0)

#define ZMLogWithLevel(level, format, ...) \
    do { \
        NSString *message = [[NSString alloc] initWithFormat:format, ##__VA_ARGS__]; \
        [ZMSLog logWithLevel:level message:^NSString * _Nonnull { \
            return message; \
        } tag:0 file:[NSString stringWithUTF8String:__FILE__] line:(NSUInteger)__LINE__]; \
    } while (0)

/// Logs an assert
FOUNDATION_EXTERN void ZMDebugAssertMessage(NSString *tag, char const * const assertion, char const * const filename, int linenumber, char const *format, ...) __attribute__((format(printf,5,6)));
