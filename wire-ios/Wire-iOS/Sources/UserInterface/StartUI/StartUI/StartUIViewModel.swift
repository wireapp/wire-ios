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

struct StartUIViewModel {

    private let viewState: StartUIViewState

    var showsGroupSelector: Bool {
        viewState.showsGroupSelector
    }

    init(viewState: StartUIViewState) {
        self.viewState = viewState
    }

    func shouldShowKeyboard(
        conversationCount: Int,
        threshold: Int
    ) -> Bool {
        viewState.shouldShowKeyboard(
            conversationCount: conversationCount,
            threshold: threshold
        )
    }

    func searchAction(
        group: SearchGroup,
        query: String
    ) -> StartUISearchAction {
        StartUISearchState(group: group, query: query).action
    }

    func shouldShowEmptyAppsSearchResultView(
        group: SearchGroup,
        query: String
    ) -> Bool {
        StartUISearchState(group: group, query: query).shouldShowEmptyAppsSearchResultView
    }
}
