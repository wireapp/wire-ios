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
import WireDataModel

extension ZMConversationMessage {
    func formattedOriginalReceivedDate() -> String? {
        guard let timestamp = serverTimestamp else {
            return nil
        }

        let formattedDate: String

        if Calendar.current.isDateInToday(timestamp) {
            formattedDate = Message.shortTimeFormatter.string(from: timestamp)
            return L10n.Localizable.Content.Message.Reply.OriginalTimestamp.time(formattedDate)

        } else {
            formattedDate = Message.shortDateFormatter.string(from: timestamp)
            return L10n.Localizable.Content.Message.Reply.OriginalTimestamp.date(formattedDate)
        }
    }

    func formattedReceivedDate() -> String? {
        serverTimestamp.map(formattedDate)
    }

    func formattedEditedDate() -> String? {
        updatedAt.map(formattedDate)
    }

    func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            Message.shortTimeFormatter.string(from: date)
        } else {
            Message.shortDateTimeFormatter.string(from: date)
        }
    }

    func formattedAccessibleMessageDetails() -> String? {
        guard let serverTimestamp else {
            return nil
        }
        let formattedTimestamp = Message.spellOutDateTimeFormatter.string(from: serverTimestamp)
        let sendDate = L10n.Localizable.MessageDetails.subtitleSendDate(formattedTimestamp)

        var accessibleMessageDetails = sendDate

        if let editTimestamp = updatedAt {
            let formattedEditTimestamp = Message.spellOutDateTimeFormatter.string(from: editTimestamp)
            let editDate = L10n.Localizable.MessageDetails.subtitleEditDate(formattedEditTimestamp)

            accessibleMessageDetails += ("\n" + editDate)
        }

        return accessibleMessageDetails
    }
}
