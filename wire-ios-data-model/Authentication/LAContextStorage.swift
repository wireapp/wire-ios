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

/// Stores a `LAContext`  to avoid repeatative authention prompts to the user.
public protocol LAContextStorable: AnyObject {
    var context: LAContext? { get set }
    func clear()
}

// `LAContextStorage` was supposed to be an actor to give thread-safe access!
// Unfortunatly the consequences are huge refactorings to Swift Concurrency
// that we could not afford in this case.

public final class LAContextStorage: LAContextStorable {

    public static let shared = LAContextStorage()

    private let internalQueue = DispatchQueue(label: "LAContextStorage.internal")
    private var internalContext: LAContext?

    public var context: LAContext? {
        get {
            return internalQueue.sync { internalContext }
        }

        set {
            internalQueue.sync { internalContext = newValue }
        }
    }

    // MARK: Funcs

    public func clear() {
        self.context = nil
    }
}
