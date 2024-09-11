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

/// User review for call quality.

enum CallQualitySurveyReview {
    /// The survey was not displayed.
    case notDisplayed(reason: IgnoreReason, duration: Int)

    /// The survey was answered by the user.
    case answered(score: Int, duration: Int)

    /// The survey was dismissed.
    case dismissed(duration: Int)

    enum IgnoreReason: String {
        case callTooShort = "call-too-short"
        case muted
    }

    // MARK: - Attributes

    /// The label of the review.
    var label: NSString {
        switch self {
        case .notDisplayed: "not-displayed"
        case .answered: "answered"
        case .dismissed: "dismissed"
        }
    }

    /// The score provided by the user.
    var score: NSNumber? {
        switch self {
        case let .answered(score, _): score as NSNumber
        default: nil
        }
    }

    /// The duration of the call.
    var callDuration: NSNumber {
        switch self {
        case let .notDisplayed(_, duration): duration as NSNumber
        case let .answered(_, duration): duration as NSNumber
        case let .dismissed(duration): duration as NSNumber
        }
    }

    /// The reason why the alert was not displayed.
    var ignoreReason: NSString? {
        switch self {
        case let .notDisplayed(reason, _): reason.rawValue as NSString
        default: nil
        }
    }
}
