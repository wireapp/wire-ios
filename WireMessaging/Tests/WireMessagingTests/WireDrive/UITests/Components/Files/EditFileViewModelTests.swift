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

import Combine
import Foundation
import Testing
import WireMessagingDomainSupport

@testable import WireMessagingDomain
@testable import WireMessagingUI

@MainActor
final class EditFileViewModelTests {

    private let mockRepository = MockWireDriveEditingURLRepositoryProtocol()
    private lazy var useCase = WireDriveGetEditingURLUseCase(editingURLRepository: mockRepository)
    private lazy var sut = EditFileViewModel(
        nodeID: UUID(),
        fileName: "document.docx",
        getEditingURLUseCase: useCase
    )

    private var capturedStates: [EditFileViewModel.State] = []
    private var cancellable: AnyCancellable?

    init() {
        self.cancellable = sut.$state.sink { [weak self] state in
            self?.capturedStates.append(state)
        }
    }

    // MARK: - Initial State

    @Test
    func initialState() async {
        // then
        #expect(sut.state == .idle)
        #expect(sut.fileName == "document.docx")
    }

    // MARK: - Success Cases

    @Test
    func load_whenSucceeds() async {
        // given
        let expectedURL = URL(string: "https://example.com/edit/document")!
        mockRepository.getEditorURLId_MockValue = (expectedURL, .distantFuture)

        // when
        await sut.load()

        // then
        #expect(capturedStates == [.idle, .loading, .loaded(expectedURL)])
    }

    // MARK: - Error Cases

    @Test
    func load_whenNilURLReturned() async {
        // given
        mockRepository.getEditorURLId_MockMethod = { _ in nil }

        // when
        await sut.load()

        // then
        #expect(capturedStates == [.idle, .loading, .unknownError])
    }

    @Test
    func load_whenNoInternet() async {
        // given
        mockRepository.getEditorURLId_MockError = URLError(.notConnectedToInternet)

        // when
        await sut.load()

        // then
        #expect(capturedStates == [.idle, .loading, .noInternetError])
    }

    @Test
    func load_whenUnknownError() async {
        // given
        mockRepository.getEditorURLId_MockError = URLError(.badServerResponse)

        // when
        await sut.load()

        // then
        #expect(capturedStates == [.idle, .loading, .unknownError])
    }

    // MARK: - Helpers

    private func unknownErrorState() -> EditFileViewModel.State {
        .error(
            title: AlertModel.unknownError.title,
            message: AlertModel.unknownError.message
        )
    }
}

private extension EditFileViewModel.State {

    static var unknownError: Self {
        .error(
            title: AlertModel.unknownError.title,
            message: AlertModel.unknownError.message
        )
    }

    static var noInternetError: Self {
        .error(
            title: AlertModel.noInternet.title,
            message: AlertModel.noInternet.message
        )
    }

}
