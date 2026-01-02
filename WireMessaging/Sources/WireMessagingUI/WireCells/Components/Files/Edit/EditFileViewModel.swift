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
    var fileName: String { get }

    func load() async
}

// MARK: - EditFileViewModel

@MainActor
final class EditFileViewModel: EditFileViewModelProtocol {

    enum State: Equatable {
        case idle
        case loading
        case loaded(URL)
        case error(title: String?, message: String)
    }

    private let nodeID: UUID
    private let getEditingURLUseCase: WireCellsGetEditingURLUseCase

    let fileName: String

    @Published private(set) var state: State = .idle

    init(
        nodeID: UUID,
        fileName: String,
        getEditingURLUseCase: WireCellsGetEditingURLUseCase
    ) {
        self.nodeID = nodeID
        self.fileName = fileName
        self.getEditingURLUseCase = getEditingURLUseCase
    }

    func load() async {
        state = .loading

        do {
            if let url = try await getEditingURLUseCase.invoke(nodeID: nodeID) {
                state = .loaded(url)
            } else {
                state = Self.errorState(for: .unknownError)
            }
        } catch where error.isNoInternetError {
            state = Self.errorState(for: .noInternet)
        } catch {
            state = Self.errorState(for: .unknownError)
        }
    }

    // MARK: - Private helpers

    private static func errorState(for alert: AlertModel) -> State {
        .error(title: alert.title, message: alert.message)
    }
}
