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

import WireDataModel

struct StartUIViewState {

    let availableSearchGroups: [SearchGroup]
    let canSeeServices: Bool
    let defaultProtocol: MessageProtocol
    let isAppsFeatureEnabled: Bool
    let areLegacyBotsAvailable: Bool

    var showsGroupSelector: Bool {
        guard availableSearchGroups.count > 1, canSeeServices else { return false }

        switch defaultProtocol {
        case .mls:
            return isAppsFeatureEnabled
        case .proteus:
            return areLegacyBotsAvailable
        case .mixed:
            return false
        }
    }

    func shouldShowKeyboard(
        conversationCount: Int,
        threshold: Int
    ) -> Bool {
        conversationCount > threshold
    }
}

struct StartUISearchState {

    let group: SearchGroup
    let query: String

    var action: StartUISearchAction {
        switch (group, query.isEmpty) {
        case (.people, true):
            return .showPeopleList
        case (.people, false):
            return .searchPeople(query)
        case (.apps, _):
            return .searchApps(query)
        case (.bots, _):
            return .searchBots(query)
        }
    }

    var shouldShowEmptyAppsSearchResultView: Bool {
        group == .apps && query.isEmpty
    }
}

enum StartUISearchAction: Equatable {
    case showPeopleList
    case searchPeople(String)
    case searchApps(String)
    case searchBots(String)
}
