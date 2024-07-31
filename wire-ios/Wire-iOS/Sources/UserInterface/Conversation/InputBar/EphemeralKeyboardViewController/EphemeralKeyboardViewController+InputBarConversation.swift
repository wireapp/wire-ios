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
import WireCommonComponents
import WireDataModel
import WireDesign

// MARK: - InputBarConversation Extension

extension InputBarConversation {

    // Properties

    var timeoutImage: UIImage? {
        guard let timeout = activeMessageDestructionTimeoutValue else { return nil }
        return timeoutImage(for: timeout)
    }

    var disabledTimeoutImage: UIImage? {
        guard let timeout = activeMessageDestructionTimeoutValue else { return nil }
        return timeoutImage(for: timeout, withColor: .lightGraphite)
    }

    ///  With this method we create the icons for the timeout in ephemeral messages
    /// - Parameters:
    ///   - timeout: Indicates the value for the timeout
    ///   - color: Indicates the color for the icons
    /// - Returns: An UIImage as the icon with the proper icon

    private func timeoutImage(for timeout: MessageDestructionTimeoutValue, withColor color: UIColor = UIColor.accent()) -> UIImage? {
        guard timeout != .none else { return nil }
        if timeout.isYears { return StyleKitIcon.timeoutYear.makeImage(size: 64, color: color) }
        if timeout.isWeeks { return StyleKitIcon.timeoutWeek.makeImage(size: 64, color: color) }
        if timeout.isDays { return StyleKitIcon.timeoutDay.makeImage(size: 64, color: color) }
        if timeout.isHours { return StyleKitIcon.timeoutHour.makeImage(size: 64, color: color) }
        if timeout.isMinutes { return StyleKitIcon.timeoutMinute.makeImage(size: 64, color: color) }
        if timeout.isSeconds { return StyleKitIcon.timeoutSecond.makeImage(size: 64, color: color) }
        return nil
    }
}
