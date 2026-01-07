//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

final class ButtonState: ZMManagedObject {
    @NSManaged private(set) var stateValue: Int16
    @NSManaged var message: ZMMessage?
    @NSManaged var remoteIdentifier: String?
    @NSManaged var isExpired: Bool

    @discardableResult
    static func insert(with id: String, message: ZMMessage, inContext moc: NSManagedObjectContext) -> ButtonState {
        let buttonState = ButtonState.insertNewObject(in: moc)
        buttonState.remoteIdentifier = id
        buttonState.message = message
        buttonState.state = .unselected
        return buttonState
    }

    override static func entityName() -> String {
        String(describing: ButtonState.self)
    }

    override static func isTrackingLocalModifications() -> Bool {
        false
    }

    var state: ButtonMessageState {
        get {
            ButtonMessageState(rawValue: stateValue) ?? .unselected
        }
        set {
            stateValue = newValue.rawValue
        }
    }
}

public enum ButtonMessageState: Int16 {
    case unselected
    case selected
    case confirmed
}

extension Set where Element: ButtonState {
    func confirmButtonState(buttonID: String?) {
        for button in self {
            button.state = if let buttonID, button.remoteIdentifier == buttonID {
                .confirmed
            } else {
                .unselected
            }
        }
    }

    func resetExpired() {
        for button in self {
            button.isExpired = false
        }
    }
}
