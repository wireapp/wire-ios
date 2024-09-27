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

import UIKit

// MARK: - Interactable

protocol Interactable {
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event)
}

// MARK: - UIControl + Interactable

extension UIControl: Interactable {}

typealias Callback<T> = (T) -> Void

// MARK: - CallbackObject

private final class CallbackObject<T: Interactable>: NSObject {
    // MARK: Lifecycle

    init(callback: @escaping Callback<T>, interactable: T, for event: UIControl.Event) {
        self.callback = callback
        super.init()
        interactable.addTarget(self, action: #selector(CallbackObject.onEvent(_:)), for: event)
    }

    // MARK: Internal

    let callback: Callback<T>

    @objc
    func onEvent(_ sender: Any!) {
        callback(sender as! T)
    }
}

extension Interactable {
    func addCallback(for event: UIControl.Event, callback: @escaping Callback<Self>) {
        let callbackContainer = CallbackObject<Self>(callback: callback, interactable: self, for: event)

        objc_setAssociatedObject(self, String(), callbackContainer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
