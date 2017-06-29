//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


extension ZMOTRMessage {

    private static let dayThreshold = 7

    @objc(shouldConfirmMessage:)
    static func shouldConfirm(_ message: ZMMessage) -> Bool {
        precondition(nil != message.serverTimestamp, "Can not decide whether to confirm message without timestamp")
        return _shouldConfirm(message)
    }

    private static func _shouldConfirm(_ message: ZMMessage, currentDate: Date = .init()) -> Bool {
        guard let timestamp = message.serverTimestamp else { return true }
        let calendar = Calendar.current
        guard let days = calendar.dateComponents([.day], from: timestamp, to: currentDate).day else { return true }
        return days <= dayThreshold
    }

}

