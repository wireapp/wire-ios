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

public enum CallQualitySurveyReview {

    /// The survey was not displayed.
    case notDisplayed(reason: IgnoreReason, duration: TimeInterval)

    /// The survey was answered by the user.
    case answered(score: Int, duration: TimeInterval)

    /// The survey was dismissed.
    case dismissed(duration: TimeInterval)

    public enum IgnoreReason: String {
        case callTooShort = "call-too-short"
        case muted
    }

    var segmentation: Set<SegmentationEntry> {
        switch self {
        case .notDisplayed(let reason, let duration):
            [
                .callLabel("not-displayed"),
                .callDuration(duration),
                .callIgnoreReason(reason.rawValue)
            ]

        case .answered(let score, let duration):
            [
                .callLabel("answered"),
                .callScore(score),
                .callDuration(duration)
            ]

        case .dismissed(let duration):
            [
                .callLabel("dismissed"),
                .callDuration(duration)
            ]
        }
    }
}
