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

public import Foundation

public final class MeetingsListViewModel: ObservableObject {

    private typealias Strings = L10n.Localizable.WireMeetings.List.Tabs

    enum Tab: Int, CaseIterable {
        case upcoming
        case past

        var title: String {
            switch self {
            case .upcoming: Strings.upcoming
            case .past: Strings.past
            }
        }
    }

    @Published var selectedTab: Tab = .upcoming
    @Published var upcomingMeetings: [Meeting] = []
    @Published var pastMeetings: [Meeting] = []

    var currentMeetings: [Meeting] {
        switch selectedTab {
        case .upcoming: upcomingMeetings
        case .past:     pastMeetings
        }
    }

    var hasMeetingsForSelectedTab: Bool { !currentMeetings.isEmpty }

    public init() {}

    func meetNowTapped() {}

    func scheduleMeetingTapped() {}

}

package struct Meeting: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let start: Date
    public let end: Date
}
