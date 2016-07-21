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
// This module of the Wire Software uses software code from Justin Spahr-Summers
// governed by the MIT license (https://github.com/jspahrsummers/libextobjc).
//
//
//  EXTScope.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//
//
//// Copyright (c) Justin Spahr-Summers
////
//// Permission is hereby granted, free of charge, to any person obtaining a copy of this
//// software and associated documentation files (the "Software"), to deal in the Software
//// without restriction, including without limitation the rights to use, copy, modify, merge,
//// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//// to whom the Software is furnished to do so, subject to the following conditions:
////
//// The above copyright notice and this permission notice shall be included in all copies or substantial
//// portions of the Software.
////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
//// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "metamacros.h"

/**
* Creates \c __weak shadow variables for each of the variables provided as
* arguments, which can later be made strong again with #strongify.
*
* This is typically used to weakly reference variables in a block, but then
* ensure that the variables stay alive during the actual execution of the block
* (if they were live upon entry).
*
* See #strongify for an example of usage.
*/
#define weakify(...) \
try {} @finally {} \
metamacro_foreach_cxt(ext_weakify_,, __weak, __VA_ARGS__)

/**
* Like #weakify, but uses \c __unsafe_unretained instead, for targets or
* classes that do not support weak references.
*/
#define unsafeify(...) \
try {} @finally {} \
metamacro_foreach_cxt(ext_weakify_,, __unsafe_unretained, __VA_ARGS__)

/**
* Strongly references each of the variables provided as arguments, which must
* have previously been passed to #weakify.
*
* The strong references created will shadow the original variable names, such
* that the original names can be used without issue (and a significantly
* reduced risk of retain cycles) in the current scope.
*
* @code

id foo = [[NSObject alloc] init];
id bar = [[NSObject alloc] init];

@weakify(foo, bar);

// this block will not keep 'foo' or 'bar' alive
BOOL (^matchesFooOrBar)(id) = ^ BOOL (id obj){
// but now, upon entry, 'foo' and 'bar' will stay alive until the block has
// finished executing
@strongify(foo, bar);

return [foo isEqual:obj] || [bar isEqual:obj];
};

* @endcode
*/
#define strongify(...) \
try {} @finally {} \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
metamacro_foreach(ext_strongify_,, __VA_ARGS__) \
_Pragma("clang diagnostic pop")

#define ext_weakify_(INDEX, CONTEXT, VAR) \
CONTEXT __typeof__(VAR) metamacro_concat(VAR, _weak_) = (VAR);

#define ext_strongify_(INDEX, VAR) \
__strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);

