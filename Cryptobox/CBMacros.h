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


#import "NSError+Cryptobox.h"

FOUNDATION_EXPORT CBErrorCode CBErrorCodeFromCBoxResult(CBoxResult result);


#define CBThrowIllegalStageExceptionIfClosed(closed) \
    do { \
        if (closed) { \
            @throw [NSException exceptionWithName:CBCodeIllegalStateException reason:@"reference closed" userInfo:nil]; \
        } \
    } while (0)

#define CBReturnWithErrorIfNotSuccess(result, error) \
    do { \
        if (result != CBOX_SUCCESS) { \
            CBErrorWithCBoxResult(result, error); \
            return; \
        } \
    } while (0);

#define CBErrorWithCBErrorCode(code, error) \
    do { \
        if (error != NULL) { \
            *error = [NSError cb_errorWithErrorCode:code]; \
        } \
    } while (0)

#define CBErrorWithCBoxResult(result, error) \
    do { \
        if (error != NULL) { \
            *error = [NSError cb_errorWithErrorCode:CBErrorCodeFromCBoxResult(result)]; \
        } \
    } while (0)

#define CBAssertResultIsSuccess(result) \
    do { \
        NSAssert(result == CBOX_SUCCESS, @""); \
    } while (0);

