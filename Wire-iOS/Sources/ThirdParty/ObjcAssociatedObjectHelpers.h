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
// This module of the Wire Software uses software code from Jon Crooke
// governed by the MIT license (https://github.com/itsthejb/ObjcAssociatedObjectHelpers).
//
//
////  ObjcAssociatedObjectHelpers.h
////  ObjcAssociatedObjectHelpers
////
////  Created by Jon Crooke on 01/10/2012.
////  Copyright (c) 2012 Jonathan Crooke. All rights reserved.
////
////  Permission is hereby granted, free of charge, to any person obtaining a copy
////  of this software and associated documentation files (the "Software"), to deal
////  in the Software without restriction, including without limitation the rights
////  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
////  copies of the Software, and to permit persons to whom the Software is
////  furnished to do so, subject to the following conditions:
////
////  The above copyright notice and this permission notice shall be included in
////  all copies or substantial portions of the Software.
////
////  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
////  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
////  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
////  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
////  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
////  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
////  SOFTWARE.


#import <objc/runtime.h>
#import <TargetConditionals.h>
#import <Availability.h>

/** Platform minimum requirements (associated object availability) */
#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR) && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_4_0
#error Associated references available from iOS 4.0
#elif TARGET_OS_MAC && ! (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_6
#error Associated references available from OS X 10.6
#endif

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark Quotation helper
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define __OBJC_ASC_QUOTE(x) #x
#define _OBJC_ASC_QUOTE(x) __OBJC_ASC_QUOTE(x)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark Dynamic perform selector helper
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define _OBJC_ASC_CHECK_AND_PERFORM(selectorName, value) {\
SEL __checkSel = NSSelectorFromString(selectorName); \
if ([self respondsToSelector:__checkSel]) { \
_Pragma ("clang diagnostic push") \
_Pragma ("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
[self performSelector:__checkSel withObject: value]; \
_Pragma ("clang diagnostic pop") \
} \
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark KVO helper
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define _OBJC_ASC_WRAP_KVO_SETTER(getterName, expression) \
_OBJC_ASC_CHECK_AND_PERFORM(@"willChangeValueForKey:", @_OBJC_ASC_QUOTE(getterName)) \
expression; \
_OBJC_ASC_CHECK_AND_PERFORM(@"didChangeValueForKey:", @_OBJC_ASC_QUOTE(getterName))

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark Assign readwrite
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define SYNTHESIZE_ASC_OBJ_ASSIGN(getterName, setterName) \
SYNTHESIZE_ASC_OBJ_ASSIGN_BLOCK(getterName, setterName, ^{}, ^{})

#define SYNTHESIZE_ASC_OBJ_ASSIGN_BLOCK(getterName, setterName, getterBlock, setterBlock) \
static void* getterName##Key = _OBJC_ASC_QUOTE(getterName); \
- (void)setterName:(id)__newValue { \
__block id value = __newValue; \
setterBlock(); \
objc_AssociationPolicy policy = OBJC_ASSOCIATION_ASSIGN; \
@synchronized(self) { \
_OBJC_ASC_WRAP_KVO_SETTER(getterName, objc_setAssociatedObject(self, getterName##Key, value, policy)); \
} \
} \
- (id) getterName { \
__block id value = nil; \
@synchronized(self) { \
value = objc_getAssociatedObject(self, getterName##Key); \
}; \
getterBlock(); \
return value; \
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark Readwrite Object
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define SYNTHESIZE_ASC_OBJ(getterName, setterName) \
SYNTHESIZE_ASC_OBJ_BLOCK(getterName, setterName, ^{}, ^{})

#define SYNTHESIZE_ASC_OBJ_BLOCK(getterName, setterName, getterBlock, setterBlock) \
static void* getterName##Key = _OBJC_ASC_QUOTE(getterName); \
- (void)setterName:(id)__newValue { \
__block id value = __newValue; \
setterBlock(); \
objc_AssociationPolicy policy = \
[value conformsToProtocol:@protocol(NSCopying)] ? OBJC_ASSOCIATION_COPY : OBJC_ASSOCIATION_RETAIN; \
@synchronized(self) { \
_OBJC_ASC_WRAP_KVO_SETTER(getterName, objc_setAssociatedObject(self, getterName##Key, value, policy)); \
} \
} \
- (id) getterName { \
__block id value = nil; \
@synchronized(self) { \
value = objc_getAssociatedObject(self, getterName##Key); \
}; \
getterBlock(); \
return value; \
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark Lazy readonly object
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define SYNTHESIZE_ASC_OBJ_LAZY_EXP(getterName, initExpression) \
SYNTHESIZE_ASC_OBJ_LAZY_EXP_BLOCK(getterName, initExpression, ^{})

#define SYNTHESIZE_ASC_OBJ_LAZY_EXP_BLOCK(getterName, initExpression, block) \
static void* getterName##Key = _OBJC_ASC_QUOTE(getterName); \
- (id)getterName { \
__block id value = nil; \
@synchronized(self) { \
value = objc_getAssociatedObject(self, getterName##Key); \
if (!value) { \
value = initExpression; \
objc_setAssociatedObject(self, getterName##Key, value, OBJC_ASSOCIATION_RETAIN); \
} \
} \
block(); \
return value; \
}

// Use default initialiser
#define SYNTHESIZE_ASC_OBJ_LAZY(getterName, class) \
SYNTHESIZE_ASC_OBJ_LAZY_EXP_BLOCK(getterName, [[class alloc] init], ^{})
#define SYNTHESIZE_ASC_OBJ_LAZY_BLOCK(getterName, class, block) \
SYNTHESIZE_ASC_OBJ_LAZY_EXP_BLOCK(getterName, [[class alloc] init], block)

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark Primitive
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#define SYNTHESIZE_ASC_PRIMITIVE(getterName, setterName, type) \
SYNTHESIZE_ASC_PRIMITIVE_BLOCK(getterName, setterName, type, ^{}, ^{})

#define SYNTHESIZE_ASC_PRIMITIVE_BLOCK(getterName, setterName, type, getterBlock, setterBlock) \
static void* getterName##Key = _OBJC_ASC_QUOTE(getterName); \
- (void)setterName:(type)__newValue { \
__block type value = __newValue; \
setterBlock(); \
@synchronized(self) { \
NSValue *nsValue = [NSValue value:&value withObjCType:@encode(type)]; \
_OBJC_ASC_WRAP_KVO_SETTER(getterName, objc_setAssociatedObject(self, getterName##Key, nsValue, OBJC_ASSOCIATION_RETAIN)); \
} \
} \
- (type) getterName { \
__block type value; \
memset(&value, 0, sizeof(type)); \
@synchronized(self) { \
[objc_getAssociatedObject(self, getterName##Key) getValue:&value]; \
} \
getterBlock(); \
return value; \
}
