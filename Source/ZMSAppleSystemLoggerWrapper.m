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


#import "ZMSAppleSystemLoggerWrapper.h"
#import "ZMSLogging.h"
#import <asl.h>
#import "ZMCSystem/ZMCSystem-swift.h"


@implementation ZMSASLClient
{
    asl_object_t _backingClient;
}

- (instancetype)init
{
    NSString *ident = [NSBundle mainBundle].bundleIdentifier ?: @"com.wire.zmessaging.test";
    return [self initWithIdentifier:ident facility:nil];
}

- (instancetype)initWithIdentifier:(NSString *)identifier facility:(NSString * __nullable)facility
{
    self = [super init];
    if (self) {
        _backingClient = asl_open(identifier.UTF8String, facility.UTF8String, ASL_OPT_STDERR);
    }
    return self;
}

- (void)sendMessage:(NSString *)message level:(ZMLogLevel_t)level;
{
    asl_object_t msg = NULL;
    int aslLevel = 0;
    switch(level) {
        case ZMLogLevelError:
            aslLevel = ASL_LEVEL_ERR;
            break;
        case ZMLogLevelWarn:
            aslLevel = ASL_LEVEL_WARNING;
            break;
        case ZMLogLevelInfo:
            aslLevel = ASL_LEVEL_INFO;
            break;
        case ZMLogLevelDebug:
            aslLevel = ASL_LEVEL_DEBUG;
            break;
    }
    aslLevel = MIN(ASL_LEVEL_NOTICE, (int) aslLevel); // if it's not at least ASL_LEVEL_NOTICE it won't show up in console
    asl_log(self->_backingClient, msg, aslLevel, "%s", message.UTF8String);
}

- (void)dealloc
{
    if (_backingClient != NULL) {
        asl_release(_backingClient);
    }
}

@end
