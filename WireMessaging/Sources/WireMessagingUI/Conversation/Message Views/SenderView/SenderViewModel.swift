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

package import Foundation
package import Combine

package class SenderViewModel: ObservableObject {

    package enum State {
        case empty
        case exists(AttributedString)
    }

    @Published var state: State

    private var cancellables: Set<AnyCancellable> = []

    package init(
        state: State,
        namePublisher: AnyPublisher<String, Never>?
    ) {
        self.state = state
        namePublisher?.sink { [weak self] name in
            self?.state = .exists(AttributedString(name))
        }.store(in: &cancellables)
    }
}
