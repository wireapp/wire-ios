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

public import SwiftUI

public extension EnvironmentValues {
    @Entry var analyticsEventTracker: (any AnalyticsEventTracker)? = .none
}

// TODO: remove commented code
//private struct AnalyticsEventTrackerKey: EnvironmentKey {
//    static let defaultValue: (any AnalyticsEventTracker)? = .none
//}
//
//public extension EnvironmentValues {
//    var analyticsEventTracker: (any AnalyticsEventTracker)? {
//        get { self[AnalyticsEventTrackerKey.self] }
//        set { self[AnalyticsEventTrackerKey.self] = newValue }
//    }
//}
//
//public extension View {
//    func analyticsEventTracker(_ analyticsEventTracker: (any AnalyticsEventTracker)?) -> some View {
//        environment(\.analyticsEventTracker, analyticsEventTracker)
//    }
//}
