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

import Foundation
import LocalAuthentication

protocol LAContextStorable {
    var context: LAContext? { get async }

    func setContext(_ context: LAContext) async
    func clear() async
}

// `LAContextStorage` was supposed to be an actor to give thread-safe access!
// Unfortunatly the consequences are huge refactorings to Swift Concurrency
// that we could not afford in this case.

/// Stores a `LAContext`  to avoid repeatative authention prompts to the user.
final class LAContextStorage: LAContextStorable {

    static let shared = LAContextStorage()

    var context: LAContext?

    func setContext(_ context: LAContext) async {
        self.context = context
    }

    func clear() async {
        self.context = nil
    }
}
