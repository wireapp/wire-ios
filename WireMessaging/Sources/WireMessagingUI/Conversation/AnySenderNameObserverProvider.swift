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

import Combine
package import WireMessagingDomain

// Need to be wrapped to type eraser as @unchecked Sendable to be able to pass to datasource actor
// also performs mapping of domain model which is just raw string
// to UI model which is Attributed string
package struct AnyObserverProvider: @unchecked Sendable {

    package let senderNameObserverProvider: SenderNameObserverProvider?
    package let reactionsObserverProvider: ReactionsObserverProvider?

    package init(
        senderNameObserverProvider: SenderNameObserverProvider?,
        reactionsObserverProvider: ReactionsObserverProvider?
    ) {
        self.senderNameObserverProvider = senderNameObserverProvider
        self.reactionsObserverProvider = reactionsObserverProvider
    }

    func get(for message: MessageModel) -> AnyPublisher<ReactionsModel, Never>? {
        reactionsObserverProvider?(message)?.reactionsPublisher
    }
}
