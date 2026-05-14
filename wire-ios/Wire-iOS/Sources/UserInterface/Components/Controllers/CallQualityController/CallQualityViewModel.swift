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

struct CallQualityViewModel {
    let questionText: String

    var titleText: String {
        L10n.Localizable.Calling.QualitySurvey.title
    }

    var skipButtonTitle: String {
        L10n.Localizable.Calling.QualitySurvey.skipButtonTitle
    }

    var closeButtonAccessibilityIdentifier: String {
        "score_close"
    }

    static func scoreRow(for score: Int) -> CallQualityScoreRowState {
        CallQualityScoreRowState(
            score: score,
            localizedName: localizedNameForScore(score)
        )
    }

    private static func localizedNameForScore(_ score: Int) -> String {
        NSLocalizedString("calling.quality_survey.answer.\(score)", comment: "")
    }
}

struct CallQualityScoreRowState {
    let score: Int
    let labelText: String
    let buttonTitle: String
    let accessibilityIdentifier: String
    let accessibilityLabel: String

    init(score: Int, localizedName: String) {
        self.score = score
        self.labelText = [1, 3, 5].contains(score) ? localizedName : ""
        self.buttonTitle = String(score)
        self.accessibilityIdentifier = "score_\(score)"
        self.accessibilityLabel = localizedName
    }
}
