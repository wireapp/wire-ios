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

import UIKit
import WireFoundation
import WireMessagingUI

final class BurstTimestampSenderMessageCellDescription: ConversationMessageCellDescription {
    typealias View = BurstTimestampSenderMessageCell

    @MainActor var conversationCellModel: ConversationCellModel? {

        let now = currentDateProvider.now
        let calendar = Calendar.current
        lazy var isToday = calendar.isDate(now, equalTo: configuration.date, toGranularity: .day)
        lazy var isYesterday = calendar.isDate(
            now.addingTimeInterval(-24 * 60 * 60),
            equalTo: configuration.date,
            toGranularity: .day
        )

        let text: String
        if configuration.showUnreadDot, !configuration.isFirstMessageOfTheDay {

            // For the unread indicator we have custom rules, unless it is the first messsage of the day.
            let difference = now.timeIntervalSince(configuration.date)
            if difference < 60 {
                // less than one minute
                text = String(localized: "time.just_now")
            } else if difference <= 30 * 60 {
                // within 30 minutes display "xy minutes ago"
                text = WRDateFormatter.timeIntervalFormatter.localizedString(for: configuration.date, relativeTo: now)
            } else if isToday {
                // for same day just show "Today"
                // the relative date formatting refers to the current system time
                let now = Date.now
                var then = now.addingTimeInterval(-60 * 60)
                if !calendar.isDate(now, equalTo: then, toGranularity: .day) {
                    then = now.addingTimeInterval(60 * 60) // in case the test runs before 01:00 AM
                }
                text = todayDateFormatter.string(from: then)
            } else if isYesterday { // for the day before show "Yesterday"
                // construct two dates with a difference between 1 and 2 days (e.g. 36h): it should return "Yesterday"
                text = WRDateFormatter.timeIntervalFormatter.localizedString(
                    for: now.addingTimeInterval(-36 * 2600),
                    relativeTo: now
                )
            } else if difference < 7 * 24 * 60 * 60 {
                // within 7 days print weekday and date
                text = weekdayAndDateDateFormatter.string(from: configuration.date)
            } else if calendar.component(.year, from: configuration.date) == calendar
                .component(.year, from: now) { // same year
                // date + month
                text = monthAndDayDateFormatter.string(from: configuration.date)
            } else {
                // date + month + year
                text = monthDayAndYearDateFormatter.string(from: configuration.date)
            }

        } else {

            if isToday {
                // for same day just show "Today"
                // the relative date formatting refers to the current system time
                let now = Date.now
                var then = now.addingTimeInterval(-60 * 60)
                if !calendar.isDate(now, equalTo: then, toGranularity: .day) {
                    then = now.addingTimeInterval(60 * 60) // in case the test runs before 01:00 AM
                }
                text = todayDateFormatter.string(from: then)
            } else if calendar.component(.year, from: configuration.date) == calendar.component(.year, from: now) {
                text = weekdayAndDateDateFormatter.string(from: configuration.date)
            } else {
                text = weekdayDateAndYearDateFormatter.string(from: configuration.date)
            }

        }

        let model = TimeDividerModel(text: text, isUnreadIndicatorVisible: configuration.showUnreadDot)
        return .timeDivider(model)

    }

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin = CGFloat()
    var bottomMargin = CGFloat()

    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    var currentDateProvider: CurrentDateProviding

    init(
        configuration: View.Configuration,
        currentDateProvider: CurrentDateProviding
    ) {
        self.configuration = configuration
        self.currentDateProvider = currentDateProvider
    }

    convenience init(
        message: ZMConversationMessage,
        context: ConversationMessageContext,
        accentColor: UIColor
    ) {
        let configuration = View.Configuration(
            date: message.serverTimestamp ?? Date(),
            isFirstMessageOfTheDay: context.isFirstMessageOfTheDay,
            showUnreadDot: context.isFirstUnreadMessage,
            accentColor: accentColor
        )
        self.init(configuration: configuration, currentDateProvider: .system)
    }

}

final class BurstTimestampSenderMessageCell: UIView, ConversationMessageCell {

    struct Configuration: Equatable {
        let date: Date
        let isFirstMessageOfTheDay: Bool
        let showUnreadDot: Bool
        let accentColor: UIColor
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {}

}

@MainActor private let todayDateFormatter = {
    let sameDayDateFormatter = DateFormatter()
    sameDayDateFormatter.timeStyle = .none
    sameDayDateFormatter.dateStyle = .medium
    sameDayDateFormatter.doesRelativeDateFormatting = true
    return sameDayDateFormatter
}()

@MainActor private let monthAndDayDateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = DateFormatter.dateFormat(
        fromTemplate: "MMM d",
        options: 0,
        locale: .current
    )
    return dateFormatter
}()

@MainActor private let monthDayAndYearDateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = DateFormatter.dateFormat(
        fromTemplate: "MMM d, yyyy",
        options: 0,
        locale: .current
    )
    return dateFormatter
}()

@MainActor private let weekdayAndDateDateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = DateFormatter.dateFormat(
        fromTemplate: "EEEEdMMM",
        options: 0,
        locale: .current
    )
    return dateFormatter
}()

@MainActor private let weekdayDateAndYearDateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = DateFormatter.dateFormat(
        fromTemplate: "EEEEdMMMYYYY",
        options: 0,
        locale: .current
    )
    return dateFormatter
}()
