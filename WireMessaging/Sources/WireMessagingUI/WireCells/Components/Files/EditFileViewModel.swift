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
import WireMessagingDomain

// MARK: - EditFileViewModelProtocol

@MainActor
protocol EditFileViewModelProtocol: ObservableObject {
    var state: EditFileViewModel.State { get }

    func load() async
}

// MARK: - EditFileViewModel

@MainActor
final class EditFileViewModel: EditFileViewModelProtocol {

    enum State {
        case idle
        case loading
        case loaded(URL)
    }

    private let nodeID: UUID
    private let getEditingURLUseCase: WireCellsGetEditingURLUseCase

    @Published private(set) var state: State = .idle

    init(
        nodeID: UUID,
        getEditingURLUseCase: WireCellsGetEditingURLUseCase
    ) {
        self.nodeID = nodeID
        self.getEditingURLUseCase = getEditingURLUseCase
    }

    func load() async {
        state = .loading

        if let url = try? await getEditingURLUseCase.invoke(nodeID: nodeID) {
            state = .loaded(url)
        }
    }
}
