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

package typealias SenderAttributedNamePublisherProvider = @Sendable (UserModel?) -> AnyPublisher<AttributedString, Never>?

// Need to be wrapped to type eraser as @unchecked Sendable to be able to pass to actor
// also performs mapping of domain model which is just raw string
// to UI model which is Attributed string
package struct AnySenderNamePublisherProvider: @unchecked Sendable {
    
    package let closure: SenderAttributedNamePublisherProvider
    
    package init(_ closure: @escaping SenderNamePublisherProvider) {
        self.closure = { model in
            guard let publisher = closure(model) else {
                return nil
            }
            return publisher // returns publisher of just raw sender name string, domain model
                .map { AttributedString($0) } // maps to UI model, attributed string
                .eraseToAnyPublisher()
        }
    }
}
