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

package import Combine
package import WireMessagingDomain
package import Foundation

package protocol SenderAttributedNameObserverProtocol {
    var authorChangedPublisher: AnyPublisher<AttributedString, Never>? { get }
}

// Need to be wrapped to type eraser as @unchecked Sendable to be able to pass to datasource actor
// also performs mapping of domain model which is just raw string
// to UI model which is Attributed string
package struct AnySenderNameObserverProvider: @unchecked Sendable {

    private var observerProvider: SenderNameObserverProvider?

    package init(
        _ observerProvider: SenderNameObserverProvider?
    ) {
        self.observerProvider = observerProvider
    }

    func get(for model: UserModel?) -> (any SenderAttributedNameObserverProtocol)? {
        SenderAttributedNameObserver(nameObserver: observerProvider?(model))
    }
}

// Mapper from raw sender name as string (domain) to Attributed string (UI layer)
package class SenderAttributedNameObserver: SenderAttributedNameObserverProtocol {

    package var authorChangedPublisher: AnyPublisher<AttributedString, Never>?

    private let nameObserver: (any SenderNameObserverProtocol)?

    package init(nameObserver: (any SenderNameObserverProtocol)?) {
        self.nameObserver = nameObserver
        if let publisher = nameObserver?.authorChangedPublisher {
            self.authorChangedPublisher = publisher
                .map { AttributedString($0) } // maps to UI model, attributed string
                .removeDuplicates()
                .eraseToAnyPublisher()
        }
    }

}
