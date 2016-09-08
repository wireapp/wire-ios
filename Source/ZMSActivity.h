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


#include <os/activity.h>
#include <os/trace.h>


//
// void ZMStartActivity(char const * description)
//
// This header declares a function ZMStartActivity(description) that will
// Start an activity, and end it once the call to ZMStartActivity goes out of scope.
//
//
//
// void ZMTraceMessage(char const * format, ...)
// -> os_trace()
//
// void ZMTraceErrorMessage(char const * format, ...)
// -> os_trace_error()
//
// void ZMTraceFaultMessage(char const * format, ...)
// -> os_trace_fault()

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
# define ZMWeakActivitySupport 0
#else
// On OS X, we support 10.9 which does not have support for activities. We're weak linking.
# define ZMWeakActivitySupport 1
#endif


extern void ZMActivityCleanup(os_activity_t * const activity);



#if ZMWeakActivitySupport


_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wunused-function\"") \
static BOOL const ZMSupportsActivities(void) __attribute__((pure));
static BOOL const ZMSupportsActivities(void)
{
    return (&_os_activity_start != NULL);
}
_Pragma("clang diagnostic pop")

# define ZMStartActivity(description) \
	os_activity_t __attribute__((cleanup(ZMActivityCleanup))) activity; \
	if (ZMSupportsActivities()) { \
		activity = os_activity_start(description, OS_ACTIVITY_FLAG_DEFAULT); \
	}

# define ZMTraceMessage(format, ...) \
	if (ZMSupportsActivities()) { \
		os_trace(format, ##__VA_ARGS__); \
	}

# define ZMTraceErrorMessage(format, ...) \
	if (ZMSupportsActivities()) { \
		os_trace_error(format, ##__VA_ARGS__); \
	}

# define ZMTraceFaultMessage(format, ...) \
	if (ZMSupportsActivities()) { \
		os_trace_fault(format, ##__VA_ARGS__); \
	}


#else // ZMWeakActivitySupport

// Platform supports activities.



# define ZMStartActivity(description) \
	os_activity_t __attribute__((cleanup(ZMActivityCleanup))) activity; \
	activity = os_activity_start(description, OS_ACTIVITY_FLAG_DEFAULT);

# define ZMTraceMessage(format, ...) \
	os_trace(format, ##__VA_ARGS__);

# define ZMTraceErrorMessage(format, ...) \
	os_trace_error(format, ##__VA_ARGS__);

# define ZMTraceFaultMessage(format, ...) \
	os_trace_fault(format, ##__VA_ARGS__);



#endif // ZMWeakActivitySupport
