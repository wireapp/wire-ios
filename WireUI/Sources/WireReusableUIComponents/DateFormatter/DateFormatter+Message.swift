//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public extension DateFormatter {
    
    static var shortTimeFormatter: DateFormatter = {
        var shortTimeFormatter = DateFormatter()
        shortTimeFormatter.dateStyle = .none
        shortTimeFormatter.timeStyle = .short
        return shortTimeFormatter
    }()

    static let shortDateFormatter: DateFormatter = {
        var shortDateFormatter = DateFormatter()
        shortDateFormatter.dateStyle = .short
        shortDateFormatter.timeStyle = .none
        return shortDateFormatter
    }()

    static let spellOutDateTimeFormatter: DateFormatter = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .long
        longDateFormatter.timeStyle = .short
        longDateFormatter.doesRelativeDateFormatting = true
        return longDateFormatter
    }()

    static let shortDateTimeFormatter: DateFormatter = {
        var longDateFormatter = DateFormatter()
        longDateFormatter.dateStyle = .short
        longDateFormatter.timeStyle = .short
        return longDateFormatter
    }()

}

public class MessageFormatter {
    
    public static func formattedOriginalReceivedDate(_ receivedAt: Date?) -> String? {
        guard let timestamp = receivedAt else {
            return nil
        }

        let formattedDate: String

        if Calendar.current.isDateInToday(timestamp) {
            formattedDate = DateFormatter.shortTimeFormatter
                .string(from: timestamp)
            return L10n.Content.Message.Reply.OriginalTimestamp.time(formattedDate)

        } else {
            formattedDate = DateFormatter.shortDateFormatter.string(from: timestamp)
            return L10n.Content.Message.Reply.OriginalTimestamp.date(formattedDate)
        }
    }

    public static func formattedReceivedTime(_ receivedAt: Date?) -> String? {
        receivedAt.map(DateFormatter.shortTimeFormatter.string(from:))
    }

    public static func formattedReceivedDateTime(_ receivedAt: Date?) -> String? {
        receivedAt.map(formattedDate)
    }

    public static func formattedEditedDate(_ updatedAt: Date?) -> String? {
        updatedAt.map(formattedDate)
    }

    public static func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            DateFormatter.shortTimeFormatter.string(from: date)
        } else {
            DateFormatter.shortDateTimeFormatter.string(from: date)
        }
    }

    public static func formattedAccessibleMessageDetails(receivedAt: Date?, updatedAt: Date?) -> String? {
        guard let receivedAt else {
            return nil
        }
        let formattedTimestamp = DateFormatter.spellOutDateTimeFormatter.string(from: receivedAt)
        let sendDate = L10n.MessageDetails.subtitleSendDate(formattedTimestamp)

        var accessibleMessageDetails = sendDate

        if let editTimestamp = updatedAt {
            let formattedEditTimestamp = DateFormatter.spellOutDateTimeFormatter.string(from: editTimestamp)
            let editDate = L10n.MessageDetails.subtitleEditDate(formattedEditTimestamp)

            accessibleMessageDetails += ("\n" + editDate)
        }

        return accessibleMessageDetails
    }

}
