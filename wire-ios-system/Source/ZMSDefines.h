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

#define ZM_UNUSED __attribute__((unused))
#define NOT_USED(x) do { (void)(x); } while (0)
#define ZM_MUST_USE_RETURN __attribute__((warn_unused_result))

/// @def ZM_WEAK
/// Helper to make a variable @c __weak before passing into a block. Use like so:
/// @code
/// ZM_WEAK(self);
/// [foo runWithHandler:^(){
///     ZM_STRONG(self);
///     [self markAsDone];
/// }];
/// @endcode
#define ZM_WEAK(a) \
	__weak typeof(a) weak_ ## a = a

#define ZM_STRONG(a) \
	_Pragma("clang diagnostic push") \
	_Pragma("clang diagnostic ignored \"-Wshadow\"") \
	__strong typeof(weak_ ## a) a = weak_ ## a; \
	_Pragma("clang diagnostic pop") \
	(void) a

#define ZM_SILENCE_CALL_TO_UNKNOWN_SELECTOR(func) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    func \
	_Pragma("clang diagnostic pop")

#define ZM_ALLOW_MISSING_SELECTOR(func) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wselector\"") \
    func \
	_Pragma("clang diagnostic pop")

#define ZM_EMPTY_ASSERTING_INIT() \
	_Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wobjc-designated-initializers\"") \
	- (instancetype)init; \
	{ \
        Require(NO); \
        return nil; \
	} \
	_Pragma("clang diagnostic pop")
