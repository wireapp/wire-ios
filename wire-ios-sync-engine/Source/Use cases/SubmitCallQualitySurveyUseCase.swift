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

public import WireFoundation
public import WireAnalytics

public protocol SubmitCallQualitySurveyUseCaseProtocol {

    func invoke(_ review: CallQualitySurveyReview)
}

public struct SubmitCallQualitySurveyUseCase: SubmitCallQualitySurveyUseCaseProtocol {

    weak var analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?

    public init(analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?) {
        self.analyticsEventTracker = analyticsEventTracker
    }

    public func invoke(_ review: CallQualitySurveyReview) {
        analyticsEventTracker?.trackEvent(.Calling.callQualitySurvey(review))
    }
}
