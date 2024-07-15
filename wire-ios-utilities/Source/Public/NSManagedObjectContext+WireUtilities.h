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

@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObjectContext (executeFetchRequestOrAssert)

/// Executes a fetch request and asserts in case of error
/// For generic requests in Swift please refer to `func fetchOrAssert<T>(request: NSFetchRequest<T>) -> [T]`
- (nonnull NSArray *)executeFetchRequestOrAssert:(nonnull NSFetchRequest *)request NS_SWIFT_UNAVAILABLE("Use `try fetch(request)` instead!");

@end

NS_ASSUME_NONNULL_END
