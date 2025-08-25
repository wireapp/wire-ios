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
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport
import WireReusableUIComponents
import Combine

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

package struct FilesView: View {
    @ObservedObject var viewModel: FilesViewModel
    @Environment(\.dismiss) var dismiss

    package init(viewModel: FilesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            List {
                Group {
                    ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, _ in
                        FilesViewItemView(viewModel: viewModel.itemViewModel(index: index))
                            .onAppear { Task { await viewModel.loadMoreIfNeeded(index: index) } }
                    }

                    if viewModel.hasMore {
                        LoadMoreView(isLoading: viewModel.isLoading, onLoadMore: loadMore)
                    }

                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .refreshable { Task { await viewModel.reload() } }
            .onAppear { Task { await viewModel.reload() } }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in
                    Button(L10n.Localizable.General.confirm, action: {})
                }
            )
            .navigationBarTitleDisplayMode(.inline)
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

    private func loadMore() {
        let lastRowIndex = viewModel.items.count - 1
        Task { await viewModel.loadMoreIfNeeded(index: lastRowIndex) }
    }
}

struct FilesViewItemView: View {

    @StateObject private var viewModel: FilesItemViewModel
    @ScaledMetric private var imageHeight: CGFloat = 28

    init(viewModel: @autoclosure @escaping () -> FilesItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    
                    Image(viewModel.icon.resource)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: imageHeight)
                        .padding(.horizontal, 4)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.fileName)
                            .wireTextStyle(.body2)
                            .lineLimit(1)
                            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                        
                        Text(viewModel.subtitle ?? "")
                            .wireTextStyle(.subline1)
                            .lineLimit(1)
                            .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    Menu {
                        if !viewModel.isDownloadOptionAvailable {
                            Button(action: download) {
                                Label(Strings.Files.Item.Menu.download, systemImage: "square.and.arrow.down.fill")
                            }.disabled(viewModel.isDownloadOptionDisabled)
                        }
                        
                        Button(action: rename) {
                            Label(Strings.Files.Item.Menu.rename, systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: delete) {
                            Label(Strings.Files.Item.Menu.delete, systemImage: "trash.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    }
                    .padding(.all, 8)
                }

                Divider()
            }

            VStack {
                Spacer()

                if let progress = viewModel.progress {
                    ProgressView(value: progress, total: 100)
                        .progressViewStyle(AssetProgressStyle(fillColor: progressColor))
                }
            }
        }
    }

    private func download() {
        Task { await viewModel.download() }
    }

    private func rename() {
        // FIXME: [WPB-19393] Implement
    }

    private func delete() {
        // FIXME: [WPB-19392] Implement
    }

    private var progressColor: Color {
        viewModel.showErrorState ? ColorTheme.Base.error.color : ColorTheme.Base.primary.color
    }

}

private struct LoadMoreView: View {
    let isLoading: Bool
    let onLoadMore: () -> Void

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Button(Strings.Files.LoadMore.title, action: onLoadMore)
                    .accessibilityLabel(Accessibility.Files.LoadMore.title)
                    .accessibilityIdentifier("load-more")
                    .buttonStyle(.borderless)
                    .wireTextStyle(.body3)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.onEnabled.color)

            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
    }

}

#Preview {
    FilesView(
        viewModel: FilesViewModel(
            fetchNodesUseCase: WireCellsFetchNodesUseCase(
                configuration: .conversationFileView(root: .path("root")),
                repository: makeNodesRepository()
            ),
            localAssetRepository: FakeLocalAssetRepository()
        )
    )
    .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}

private func makeNodesRepository() -> MockWireCellsNodesRepositoryProtocol {
    let repository = MockWireCellsNodesRepositoryProtocol()
    repository.getNodes_MockMethod = { request in
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay

        if request.offset >= 120 {
            throw URLError(.notConnectedToInternet)
        }

        let nodes = (request.offset ..< request.offset + 30).map { index in
            WireCellsNode(
                uuid: UUID(),
                path: "root/foo-\(index).jpg",
                modified: Date(),
                mimeType: "image/jpeg",
                ownerUserName: "Person \(index)",
            )
        }
        let nextOffset = request.offset + 30
        return (nodes, nextOffset)
    }
    return repository
}

private class FakeLocalAssetRepository: WireCellsLocalAssetRepositoryProtocol {

    private var failIndex = 0
    private var assets: [UUID: CurrentValueSubject<WireCellsLocalAsset?, Never>] = [:]

    func asset(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAsset? {
        assets[nodeID]?.value
    }
    
    func refreshMetadata(nodeID: UUID) async throws {}
    
    func downloadAsset(nodeID: UUID) async throws {
        failIndex += 1
        // Fail every 3rd download
        let shouldFail = failIndex % 3 == 0

        for progress in 0...100 {
            let downloadState: WireCellsLocalAsset.DownloadState = if shouldFail && progress > 10 {
                .failed(error: URLError(.notConnectedToInternet))
            } else if progress < 100 {
                .downloading(progress: Double(progress))
            } else {
                .downloaded(cacheKey: "cacheKey")
            }

            try await Task.sleep(nanoseconds: 50_000_000)
            assets[nodeID]?.send(
                WireCellsLocalAsset(
                    nodeID: nodeID,
                    eTag: "something",
                    path: "some/path.jpg",
                    contentType: nil,
                    size: nil,
                    downloadState: downloadState
                )
            )
            if shouldFail && progress > 10 {
                break
            }
        }
    }
    
    func observeAsset(nodeID: UUID) -> AnyPublisher<WireCellsLocalAsset?, Never> {
        let publisher = assets[nodeID] ?? CurrentValueSubject<WireCellsLocalAsset?, Never>(nil)
        assets[nodeID] = publisher
        return publisher.eraseToAnyPublisher()
    }
    
    func cancelDownload(nodeID: UUID) {}

}
