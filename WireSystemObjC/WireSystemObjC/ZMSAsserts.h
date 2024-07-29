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

#import <AssertMacros.h>
#import <WireSystemObjC/ZMSDefines.h>

#define Require(assertion) do { \
    if ( __builtin_expect(!(assertion), 0) ) { \
        ZMCrash(#assertion, __FILE__, __LINE__); \
    } \
} while (0)

#define RequireString(assertion, frmt, ...) do { \
    if ( __builtin_expect(!(assertion), 0) ) { \
        ZMCrashFormat(#assertion, __FILE__, __LINE__, frmt, ##__VA_ARGS__); \
    } \
} while (0)

#define VerifyAction(assertion, action) \
    do { \
        if ( __builtin_expect(!(assertion), 0) ) { \
            ZMDebugAssertMessage(@"Verify", #assertion, __FILE__, __LINE__); \
            action; \
        } \
    } while (0)

#define VerifyReturn(assertion) \
    VerifyAction(assertion, return)

#define VerifyReturnValue(assertion, value) \
    VerifyAction(assertion, return (value))

#define VerifyReturnNil(assertion) \
    VerifyAction(assertion, return nil)

#define VerifyString(assertion, frmt, ...) \
    do { \
        if ( __builtin_expect(!(assertion), 0) ) { \
            ZMDebugAssertMessageWithFormat(@"Verify", #assertion, __FILE__, __LINE__, @frmt, ##__VA_ARGS__); \
        } \
    } while (0)

#define VerifyActionString(assertion, action, frmt, ...) \
    do { \
        if ( __builtin_expect(!(assertion), 0) ) { \
            ZMDebugAssertMessageWithFormat(@"Verify", #assertion, __FILE__, __LINE__, @frmt, ##__VA_ARGS__); \
            action; \
        } \
    } while (0)

#define Check(assertion) \
    do { \
        if ( __builtin_expect(!(assertion), 0) ) { \
            ZMDebugAssertMessage(@"Verify", #assertion, __FILE__, __LINE__); \
        } \
    } while (0)

#define CheckString(assertion, frmt, ...) \
    do { \
        if ( __builtin_expect(!(assertion), 0) ) { \
            ZMDebugAssertMessageWithFormat(@"Verify", #assertion, __FILE__, __LINE__, @frmt, ##__VA_ARGS__); \
        } \
    } while (0)

#define ZMDebugAssertMessage(tag_, assertion, file_, line_) \
    do { \
        NSString *message = [NSString stringWithFormat:@"Assertion (%s) failed.", assertion]; \
        [ZMSLog logWithLevel:ZMLogLevelError message:^NSString * _Nonnull { \
            return message; \
        } tag:tag_ file:[NSString stringWithUTF8String:file_] line:(NSUInteger)line_]; \
    } while (0)

#define ZMDebugAssertMessageWithFormat(tag_, assertion, file_, line_, format, ...) \
    do { \
        NSString *prefix = [NSString stringWithFormat:@"Assertion (%s) failed. ", assertion]; \
        NSString *message = [prefix stringByAppendingFormat:format, ##__VA_ARGS__]; \
        [ZMSLog logWithLevel:ZMLogLevelError message:^NSString * _Nonnull { \
            return message; \
        } tag:tag_ file:[NSString stringWithUTF8String:file_] line:(NSUInteger)line_]; \
    } while (0)

#pragma mark -

#define ZMCrash(reason, file, line) \
do { \
    NSString *output = [NSString stringWithFormat:@"ASSERT: [%s:%d] <%s> %s", \
                        file != NULL ? file : "", \
                        line, \
                        reason != NULL ? reason : "", \
                        ""]; \
\
    /* report error to datadog or other loggers */ \
    [WireLoggerObjc assertionDumpLog:output]; \
\
    /* prepare and dump to file */ \
    [ZMAssertionDumpFile writeWithContent:output error:nil]; \
\
    __builtin_trap(); \
} while(0)

#define ZMCrashFormat(reason, file, line, format, ...) \
do { \
    NSString *message = [NSString stringWithFormat: @format, ##__VA_ARGS__]; \
    NSString *output = [NSString stringWithFormat:@"ASSERT: [%s:%d] <%s> %@", \
                        file != NULL ? file : "", \
                        line, \
                        reason != NULL ? reason : "", \
                        message]; \
\
    /* report error to datadog or other loggers */ \
    [WireLoggerObjc assertionDumpLog:output]; \
\
    /* prepare and dump to file */ \
    [ZMAssertionDumpFile writeWithContent:output error:nil]; \
\
    __builtin_trap(); \
} while(0)
