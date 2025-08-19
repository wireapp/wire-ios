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

import SwiftUI
import WireDesign
import WireMessagingDomain
import WireMessagingDomainSupport

package struct FilesView: View {
    @ObservedObject var viewModel: FilesViewModel
    @Environment(\.dismiss) var dismiss

    private typealias Strings = L10n.Localizable.Conversation.WireCells
    private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

    package init(viewModel: FilesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, _ in
                    FilesViewItemView(viewModel: viewModel.itemViewModel(index: index))
                        .onAppear { Task { await viewModel.loadMoreIfNeeded(index: index) } }
                }
            }
            .onAppear { Task { await viewModel.reload() } }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Strings.Files.navigationTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SemanticColors.Label.textDefault.color)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(.close)
                            .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
                    }
                    .accessibilityLabel(Accessibility.Files.close)
                    .accessibilityIdentifier("close")
                }
            }
        }
    }
}

private struct FilesViewItemView: View {
    @StateObject var viewModel: FilesItemViewModel

    init(viewModel: @autoclosure @escaping () -> FilesItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack {
            Text(viewModel.fileName)
            Text(viewModel.subtitle ?? "")
        }

    }
}

#Preview {
    FilesView(
        viewModel: FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(root: .path("root")),
                repository: makeNodesRepository()
            )
        )
    )
}

private func makeNodesRepository() -> MockWireCellsNodesRepositoryProtocol {
    let repository = MockWireCellsNodesRepositoryProtocol()
    repository.getNodes_MockMethod = { request in
        let nodes = (request.offset ..< request.offset + 30).map { index in
            WireCellsNode(
                uuid: UUID(),
                path: "root/foo-\(index).jpg",
                modified: UInt64(Date().timeIntervalSince1970),
                ownerUserName: "Person \(index)"
            )
        }
        let nextOffset = request.offset == 0 ? 30 : nil
        return (nodes, nextOffset)
    }
    return repository
}
