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
import Combine
import WireMessagingDomain

class ReactionsViewModel: ObservableObject {

    package enum State {
        case empty
        case exists(ReactionsModel)
    }

    @Published var state: State

    private var cancellables: Set<AnyCancellable> = []

    init(
        state: State,
        publisher: AnyPublisher<ReactionsModel, Never>?
    ) {
        self.state = state
        publisher?.sink { [weak self] reactions in
            self?.state = Self.state(from: reactions)
        }.store(in: &cancellables)
    }
    
    static func state(from reactions: ReactionsModel) -> State {
        reactions.hasReactions() ? .exists(reactions): .empty
    }
}
