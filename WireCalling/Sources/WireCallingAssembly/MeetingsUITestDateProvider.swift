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

#if DEBUG
    import Foundation
    import notify
    import WireFoundation

    final class MeetingsUITestDateProvider: CurrentDateProviding, @unchecked Sendable {

        private let lock = NSLock()
        private var date: Date
        private var notificationToken: Int32 = NOTIFY_TOKEN_INVALID

        var now: Date {
            lock.lock()
            defer { lock.unlock() }
            return date
        }

        init(now: Date, clockID: String?) {
            self.date = now
            guard let clockID else { return }
            let name = "\(UITestConfig.meetingsClockNotificationPrefix).\(clockID)"
            let status = name.withCString {
                notify_register_dispatch($0, &notificationToken, .main) { [weak self] _ in
                    self?.advanceOneLocalDay()
                }
            }
            precondition(status == NOTIFY_STATUS_OK)
        }

        deinit {
            if notificationToken != NOTIFY_TOKEN_INVALID {
                notify_cancel(notificationToken)
            }
        }

        private func advanceOneLocalDay() {
            let oldDate = now
            let calendar = Calendar.current
            guard let nextMidnight = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: oldDate)
            ) else { return }
            lock.lock()
            date = nextMidnight.addingTimeInterval(60)
            lock.unlock()
            NotificationCenter.default.post(name: .NSCalendarDayChanged, object: nil)
        }

    }
#endif
