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


#import "ZMSLogging.h"
#import "ZMSLogging+Testing.h"
#import <asl.h>
#import <dlfcn.h>
#import <map>
#import <string>

static const ZMLogLevel_t ZMDefaultLogLevel = ZMLogLevelWarn;
static const int ZMLogSnapshotCount = 10000;

// used to debug
void (^ZMLoggingDebuggingHook)(char const *tag, char const * const filename, int linenumber, NSString *output) = 0;

/// Allows to debug invocations of logs, by invoking the custom log debug hook
void ZMLogDebugger(char const *tag, char const * const filename, int linenumber, char const * const output, NSString * objcOutput) __attribute__((noinline)) __attribute__((visibility("default")));
const char *

/// Returns the ASL string matching the passed log level (0 to 9)
ZMLogStringFromMessageValue(const char *logLevel);


static dispatch_group_t logGroup = dispatch_group_create();

static dispatch_queue_t logQueue(void)
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("ZMLog", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static aslclient logClient(void)
{
    static aslclient client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            client = asl_open([[[NSBundle mainBundle] bundleIdentifier] UTF8String], NULL, ASL_OPT_STDERR);
        }
    });
    return client;
}

void ZMLog(char const *tag, char const * const filename, int linenumber, ZMLogLevel_t logLevel, NSString *format, ...)
{
    if(tag != 0) {
        ZMLogInitForTag(tag);
        const ZMLogLevel_t currentLevel = ZMLogGetLevelForTag(tag);
        if (__builtin_expect((logLevel > currentLevel),1)) {
            return;
        }
    }
    
    @autoreleasepool {
        va_list args;
        va_start(args, format);
        NSString *output = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        
        int static const aslLevels[] = {ASL_LEVEL_ERR, ASL_LEVEL_WARNING, ASL_LEVEL_INFO, ASL_LEVEL_DEBUG};
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-constant-out-of-range-compare"
        int const matchingAslLevel = (sizeof(aslLevels) / sizeof(*aslLevels) < logLevel) ? ASL_LEVEL_ERR : aslLevels[logLevel];
#pragma clang diagnostic pop

        dispatch_sync(logQueue(), ^{
            // make sure that it is at least ASL_LEVEL_NOTICE, or it won't be visible in console
            int aslLevel = matchingAslLevel > ASL_LEVEL_NOTICE ? ASL_LEVEL_NOTICE : matchingAslLevel;
            (void) asl_log(logClient(), NULL, aslLevel, "[%s] %s", tag == 0 ? "" : tag, [output UTF8String]);
        });
     
        if (logLevel <= ZMLogLevelWarn) {
            ZMLogDebugger(tag, filename, linenumber, NULL, output);
        }
    }
}

void ZMDebugAssertMessage(char const *tag, char const * const assertion, char const * const filename, int linenumber, char const * const format, ...)
{
    @autoreleasepool {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"EnableAssertLogging": @YES}];
        });
        
        char * message = NULL;
        va_list ap;
        va_start(ap, format);
        if ((format == NULL) || (vasprintf(&message, format, ap) == 0)) {
            message = NULL;
        }
        va_end(ap);
        
        dispatch_sync(logQueue(), ^{
            if (message == NULL) {
                (void) asl_log(logClient(), NULL, ASL_LEVEL_ERR, "%s:%d: [%s] Assertion (%s) failed.", filename, linenumber, tag, assertion);
            } else {
                (void) asl_log(logClient(), NULL, ASL_LEVEL_ERR, "%s:%d: [%s] Assertion (%s) failed. %s", filename, linenumber, tag, assertion, message);
            }
        });

        ZMLogDebugger(tag, filename, linenumber, message != 0 ? message : assertion, nil);
    }
}

void ZMLogDebugger(char const *tag, char const * const filename, int linenumber, char const * const output, NSString * objcOutput)
{
    // Do nothing.
    if(ZMLoggingDebuggingHook != nil) {
        if ((objcOutput == nil) && (output != NULL)) {
            objcOutput = [NSString stringWithUTF8String:output];
        }
        ZMLoggingDebuggingHook(tag, filename, linenumber, objcOutput);
    }
}


#pragma mark - Turning logs on and off

static std::map<std::string, ZMLogLevel_t> _logTagToLevel;

static dispatch_queue_t zmLogIsolationQueue() {
    static dispatch_queue_t isolationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // this should work better with DISPATCH_QUEUE_CONCURRENT and the barriers. However, it does not work.
        // It deadlocks or crashes because of concurrent access. There is something odd going on. Switching to serial
        // for the time being
        isolationQueue = dispatch_queue_create("ZMLogLevel.isolation", DISPATCH_QUEUE_SERIAL);
    });
    return isolationQueue;
}

void ZMLogSetLevelForTag(ZMLogLevel_t level, const char *tag) {
    const std::string constTag = tag; // need to do this because the 'tag' memory might be trashed
    dispatch_group_enter(logGroup);
    dispatch_sync(zmLogIsolationQueue(), ^{
        _logTagToLevel[constTag] = level;
        dispatch_group_leave(logGroup);
    });
}

ZMLogLevel_t ZMLogGetLevelForTag(const char *tag __unused) {
    __block ZMLogLevel_t level;
    dispatch_sync(zmLogIsolationQueue(), ^{ // TODO
        auto found = _logTagToLevel.find(tag);
        if(found == _logTagToLevel.end()) {
            level = ZMDefaultLogLevel;
        }
        else {
            level = found->second;
        }
    });
    return level;
}

NSSet* ZMLogGetAllTags(void) {
    NSMutableSet *results = [NSMutableSet set];
    dispatch_sync(zmLogIsolationQueue(), ^{
        for(auto const &pair : _logTagToLevel) {
            [results addObject:[NSString stringWithUTF8String:pair.first.c_str()]];
        }
    });
    return results;
}

void ZMLogInitForTag(const char *tag) {
    const std::string constTag = tag; // need to do this because the 'tag' memory might be trashed
    dispatch_group_enter(logGroup);
    dispatch_barrier_async(zmLogIsolationQueue(), ^{
        if(_logTagToLevel.find(constTag) == _logTagToLevel.end()) {
            _logTagToLevel[constTag] = ZMDefaultLogLevel;
        }
        dispatch_group_leave(logGroup);
    });
}

void ZMLogSynchronize() {
    dispatch_group_wait(logGroup, DISPATCH_TIME_FOREVER);
}


void ZMLogSnapshot(NSString *filepath)
{
    dispatch_sync(zmLogIsolationQueue(), ^{
        
        NSMutableData *constructedData = [NSMutableData dataWithCapacity:ZMLogSnapshotCount * (sizeof(char) * 60)];
        
        aslmsg query, message;
        const char *key, *value;
        int messageSnapshotedCount;
        
        const char *IgnoredKeys[] = { ASL_KEY_MSG_ID, ASL_KEY_TIME_NSEC, ASL_KEY_READ_GID, ASL_KEY_HOST, ASL_KEY_SENDER_MACH_UUID};
        unsigned int IgnoredKeyCount = sizeof(IgnoredKeys) / sizeof(IgnoredKeys[0]);
        
        query = asl_new(ASL_TYPE_QUERY);
        
        aslresponse result = asl_search(NULL, query);
        asl_reset_iteration(result, SIZE_MAX); // put the iterator at the end
        asl_release(query);
        
        // iterate from end to begin
        messageSnapshotedCount = 0;
        while(ZMLogSnapshotCount > messageSnapshotedCount && NULL != (message = asl_prev(result)) ) {
            
            // filter out couple of data we don't need
            for (unsigned int i = 0; i < IgnoredKeyCount; ++i) {
                asl_unset(message, IgnoredKeys[i]);
            }
            
            for (unsigned int i = 0; (NULL != (key =  asl_key(message, i) )); ++i)
            {
                value = asl_get(message, key);
                if (NULL == value) {
                    continue;
                }
                
                const char *finalValue = value;
                if (0 == strcmp(ASL_KEY_LEVEL, key)) {
                    finalValue = ZMLogStringFromMessageValue(value);
                }
                
                [constructedData appendBytes:key length:strlen(key)];
                [constructedData appendBytes:" - " length:3];
                [constructedData appendBytes:finalValue length:strlen(finalValue)];
                [constructedData appendBytes:" | " length:3];
            }
            [constructedData appendBytes:"\n" length:1];
            ++messageSnapshotedCount;
        }
        asl_release(result);
        [[NSFileManager defaultManager] createFileAtPath:filepath contents:[constructedData copy] attributes:nil];
    });
    
}

void ZMLogTestingResetLogLevels() {
    dispatch_barrier_sync(zmLogIsolationQueue(), ^{
        _logTagToLevel.clear();
    });

}

const char *
ZMLogStringFromMessageValue(const char *logLevel)
{
    if (0 == strcmp(logLevel, "0")) {
        return ASL_STRING_EMERG;
    } else if (0 == strcmp(logLevel, "1")) {
        return ASL_STRING_ALERT;
    } else if (0 == strcmp(logLevel, "2")) {
        return ASL_STRING_CRIT;
    } else if (0 == strcmp(logLevel, "3")) {
        return ASL_STRING_ERR;
    } else if (0 == strcmp(logLevel, "4")) {
        return ASL_STRING_WARNING;
    } else if (0 == strcmp(logLevel, "5")) {
        return ASL_STRING_NOTICE;
    } else if (0 == strcmp(logLevel, "6")) {
        return ASL_STRING_INFO;
    } else if (0 == strcmp(logLevel, "7")) {
        return ASL_STRING_DEBUG;
    }
    return NULL;
}
