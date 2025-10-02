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

public final class MeetingsListViewModel: ObservableObject {

    enum Tab: Int, CaseIterable {
        case upcoming = 0
        case past = 1

        var title: String {
            switch self {
            case .upcoming: return "Upcoming"
            case .past: return "Past"
            }
        }
    }

    @Published var selectedTab: Tab = .upcoming

    public init() {}

    func meetNowTapped() {
        print("Meet Now tapped")
    }

    func scheduleMeetingTapped() {
        print("Schedule a Meeting tapped")
    }

    var accessibilityHintForAvatar: String = "Opens account menu"

}
