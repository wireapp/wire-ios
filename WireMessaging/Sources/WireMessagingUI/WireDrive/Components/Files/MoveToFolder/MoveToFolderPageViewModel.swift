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
import SwiftUI
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

// MARK: - MoveToFolderPageViewModelProtocol

@MainActor
protocol MoveToFolderPageViewModelProtocol: ObservableObject {
    associatedtype CreateFileView: View

    var title: String { get }
    var content: MoveToFolderPageViewModel.ContentState { get }
    var moveButtonState: MoveToFolderPageViewModel.MoveButtonState { get }
    var isNewFolderEnabled: Bool { get }
    var navigationMenuOptions: [NavigationMenuOption] { get }
    var showCancelButton: Bool { get }
    var alert: AlertModel? { get set }
    var sheetNavigation: MoveToFolderPageViewModel.SheetNavigation? { get set }

    func select(item: MoveToFolderItem)
    func reload() async
    func loadMore() async
    func move() async
    func createFolder()
    func navigateTo(option: NavigationMenuOption)
    func cancel()
    func makeCreateFileView() -> CreateFileView

}

// MARK: - Move to folder page models

struct MoveToFolderItem: Identifiable, Hashable, Sendable {

    /// The unique identifier of the item.
    let id: UUID

    /// The name of the user who owns (uploaded or created) this item.
    let name: String

    /// The subtitle of the item, typically containing additional information such as modification date or owner.
    let subtitle: String?

}

// MARK: - MoveToFolderPageViewModel

@MainActor
final class MoveToFolderPageViewModel: MoveToFolderPageViewModelProtocol {

    /// The main content to be displayed in the Move to Folder page
    enum ContentState: Hashable, Sendable {

        case initialLoad
        case loaded(items: [MoveToFolderItem], hasMore: Bool, isLoading: Bool)
        case empty(title: String?, message: String, showsReload: Bool)

    }

    /// The state of the move button
    enum MoveButtonState {

        case enabled
        case disabled
        case loading

    }

    enum SheetNavigation: Identifiable {
        case createFolder

        var id: Self { self }
    }

    private let containerPath: String
    private let originalContainerPath: String
    private let nodeID: UUID
    private let nodeName: String
    private let onNavigate: (String) -> Void
    private let onFinish: () -> Void
    private let nodesCollection: WireDriveNodesCollection
    private let fetchNodesUseCase: WireDriveFetchNodesUseCase
    private let moveNodeUseCase: WireDriveMoveNodeUseCase
    private let createFileUseCase: any WireDriveCreateFileUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()

    let title: String

    @Published private var nodes: [WireDriveNode] = []
    @Published private var isMoving = false
    @Published private var isLoadingContent = false
    @Published private var loadingContentError: (any Error)?
    @Published private var hasMoreContent = true
    @Published var alert: AlertModel?
    @Published var sheetNavigation: SheetNavigation?

    init(
        containerPath: String,
        originalContainerPath: String,
        nodeID: UUID,
        nodeName: String,
        onNavigate: @escaping (String) -> Void,
        onFinish: @escaping () -> Void,
        nodesCollection: WireDriveNodesCollection,
        fetchNodesUseCase: WireDriveFetchNodesUseCase,
        moveNodeUseCase: WireDriveMoveNodeUseCase,
        createFileUseCase: any WireDriveCreateFileUseCaseProtocol
    ) {
        self.title = Self.title(for: containerPath)
        self.nodeID = nodeID
        self.nodeName = nodeName
        self.containerPath = containerPath
        self.originalContainerPath = originalContainerPath
        self.onNavigate = onNavigate
        self.onFinish = onFinish
        self.nodesCollection = nodesCollection
        self.fetchNodesUseCase = fetchNodesUseCase
        self.moveNodeUseCase = moveNodeUseCase
        self.createFileUseCase = createFileUseCase

        nodesCollection.observeNodes().sink { [weak self] nodes in
            self?.nodes = nodes.filter { $0.id != nodeID }
        }.store(in: &subscriptions)
    }

    var items: [MoveToFolderItem] {
        nodes.map { node in
            MoveToFolderItem(
                id: node.id,
                name: node.name,
                subtitle: Self.subtitle(
                    modifiedAt: node.modified,
                    ownedBy: node.ownerUserName,
                    locale: .autoupdatingCurrent,
                    calendar: .autoupdatingCurrent,
                    timeZone: .autoupdatingCurrent
                )
            )
        }
    }

    var navigationMenuOptions: [NavigationMenuOption] {
        var pathComponents = containerPath.components(separatedBy: "/").dropLast()

        var options: [NavigationMenuOption] = []
        while !pathComponents.isEmpty {
            let path = pathComponents.joined(separator: "/")
            options.append(
                NavigationMenuOption(
                    path: path,
                    title: Self.title(for: path),
                    isRoot: pathComponents.count == 1
                )
            )
            pathComponents.removeLast()
        }

        return options
    }

    var showCancelButton: Bool {
        navigationMenuOptions.isEmpty
    }

    var content: ContentState {
        switch (isLoadingContent, nodes.isEmpty) {
        case (true, true):
            return .initialLoad
        case (true, false):
            return .loaded(items: items, hasMore: hasMoreContent, isLoading: true)
        case (false, false):
            return .loaded(items: items, hasMore: hasMoreContent, isLoading: false)
        case (false, true):
            if let error = loadingContentError {
                let alert = Self.alert(error: error)
                return .empty(
                    title: alert.title,
                    message: alert.message,
                    showsReload: true
                )
            } else {
                return .empty(
                    title: nil,
                    message: Strings.Files.MoveToFolder.noSubfolders,
                    showsReload: false
                )
            }
        }
    }

    var moveButtonState: MoveButtonState {
        if isMoving {
            .loading
        } else if !isValidContentLoaded || containerPath == originalContainerPath {
            .disabled
        } else {
            .enabled
        }
    }

    var isNewFolderEnabled: Bool {
        isValidContentLoaded
    }

    func select(item: MoveToFolderItem) {
        guard let node = nodes.first(where: { $0.id == item.id }) else { return }

        onNavigate(node.path)
    }

    func reload() async {
        await loadContent(isReload: true)
    }

    func loadMore() async {
        await loadContent(isReload: false)
    }

    func move() async {
        guard isMoving == false else { return }

        isMoving = true
        do {
            try await moveNodeUseCase.invoke(nodeID: nodeID, containerPath: containerPath)
            onFinish()
        } catch {
            alert = Self.alert(error: error)
        }
        isMoving = false
    }

    func createFolder() {
        sheetNavigation = .createFolder
    }

    func navigateTo(option: NavigationMenuOption) {
        onNavigate(option.path)
    }

    func cancel() {
        onFinish()
    }

    func makeCreateFileView() -> some View {
        // swiftformat:disable:next redundantSelf
        WireMessagingUI.CreateFileView(viewModel: self.makeCreateFileViewModel())
    }

    private func makeCreateFileViewModel() -> CreateFileViewModel {
        let viewModel = CreateFileViewModel(
            creationTarget: .folder,
            path: containerPath,
            createFileUseCase: createFileUseCase
        )

        viewModel.$createdNode
            .compactMap(\.self)
            .sink { [weak self] _ in
                Task { await self?.reload() }
            }.store(in: &subscriptions)

        return viewModel
    }

    /// Returns the title for a given path.
    ///
    /// If there is only a single path component this is the conversation ID. Therefore we return a default title.
    private static func title(for path: String) -> String {
        path.components(separatedBy: "/").dropFirst().last ?? L10n.Localizable.Conversation.WireCells.Files
            .navigationTitle
    }
    
    private static func subtitle(
        modifiedAt: Date?,
        ownedBy: String?,
        locale: Locale,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> String? {
        let modifiedAt = modifiedAt.map { date in
            let style = Date.FormatStyle(
                date: .abbreviated,
                time: .shortened,
                locale: locale,
                calendar: calendar,
                timeZone: timeZone,
                capitalizationContext: .beginningOfSentence
            )
            return date.formatted(style)
        }
        return if let modifiedAt, let ownedBy {
            L10n.Localizable.Conversation.WireCells.Files.Item.subtitle(modifiedAt, ownedBy)
        } else {
            [modifiedAt, ownedBy].compactMap(\.self).first
        }
    }

    // MARK: - Private Helpers

    private func loadContent(isReload: Bool) async {
        guard isLoadingContent == false else { return }

        loadingContentError = nil
        isLoadingContent = true
        do {
            hasMoreContent = try await fetchNodesUseCase.invoke(request: .reload(searchTerm: nil)).hasMore
        } catch where error.isURLErrorCancelled {
            // no op
        } catch {
            loadingContentError = error
            if !nodes.isEmpty {
                alert = Self.alert(error: error)
            }
        }
        isLoadingContent = false
    }

    /// Whether valid content is loaded (either loaded with items or empty without error).
    private var isValidContentLoaded: Bool {
        switch content {
        case .initialLoad:
            false
        case .loaded:
            true
        case .empty:
            loadingContentError == nil
        }
    }

    private static func alert(error: any Error) -> AlertModel {
        if error.isNoInternetError {
            .noInternet
        } else {
            .unknownError
        }
    }

}

// MARK: - MockMoveToFolderPageViewModel

@MainActor
final class MockMoveToFolderPageViewModel: MoveToFolderPageViewModelProtocol {

    let title: String
    let content: MoveToFolderPageViewModel.ContentState
    let moveButtonState: MoveToFolderPageViewModel.MoveButtonState
    let isNewFolderEnabled: Bool
    let navigationMenuOptions: [NavigationMenuOption]
    let showCancelButton: Bool
    var alert: AlertModel?
    var sheetNavigation: MoveToFolderPageViewModel.SheetNavigation?

    init(
        title: String = "Files",
        content: MoveToFolderPageViewModel.ContentState = .initialLoad,
        moveButtonState: MoveToFolderPageViewModel.MoveButtonState = .disabled,
        isNewFolderEnabled: Bool = false,
        navigationMenuOptions: [NavigationMenuOption] = [],
        showCancelButton: Bool = false,
        alert: AlertModel? = nil
    ) {
        self.title = title
        self.content = content
        self.moveButtonState = moveButtonState
        self.isNewFolderEnabled = isNewFolderEnabled
        self.navigationMenuOptions = navigationMenuOptions
        self.showCancelButton = showCancelButton
        self.alert = alert
    }

    func select(item: MoveToFolderItem) {}
    func reload() async {}
    func loadMore() {}
    func move() async {}
    func createFolder() {}
    func navigateTo(option: NavigationMenuOption) {}
    func cancel() {}
    func makeCreateFileView() -> some View {
        EmptyView()
    }

}
