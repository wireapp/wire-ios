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
import SwiftUI
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

private typealias Strings = L10n.Localizable.Conversation.WireCells

// MARK: - MoveToFolderView Models

struct NavigationMenuOption: Hashable, Sendable {

    /// The wire drive path of the navigation option.
    let path: String

    /// The title of the navigation option.
    let title: String

    /// Whether this option represents the root collection. E.g. a conversation.
    let isRoot: Bool
}

// MARK: - MoveToFolderViewModelProtocol

@MainActor
protocol MoveToFolderViewModelProtocol: ObservableObject {
    associatedtype MoveToFolderPage: View

    var rootPath: String { get }

    var navigationPath: [MoveToFolderViewModel.FilesNavigationItem] { get set }

    func makeView(path: String) -> MoveToFolderPage

}

// MARK: - MoveToFolderViewModel

@MainActor
final class MoveToFolderViewModel: MoveToFolderViewModelProtocol {

    struct FilesNavigationItem: Hashable {
        let path: String

        static func items(for path: String) -> [FilesNavigationItem] {
            var pathComponents = path.components(separatedBy: "/")

            var options: [FilesNavigationItem] = []
            while !pathComponents.isEmpty {
                options.append(FilesNavigationItem(path: pathComponents.joined(separator: "/")))
                pathComponents.removeLast()
            }

            return Array(options.reversed().dropFirst())
        }
    }

    let rootPath: String

    private let originalContainerPath: String
    private let nodeID: UUID
    private let nodeName: String
    private let onFinish: () -> Void
    private let nodesRepository: any WireDriveNodesRepositoryProtocol
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    private let moveNodeUseCase: WireDriveMoveNodeUseCase
    private let createUseCase: any WireDriveCreateUseCaseProtocol

    @Published var navigationPath: [FilesNavigationItem]

    init(
        containerPath: String,
        nodeID: UUID,
        nodeName: String,
        onFinish: @escaping () -> Void,
        nodesRepository: any WireDriveNodesRepositoryProtocol,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol,
        moveNodeUseCase: WireDriveMoveNodeUseCase,
        createUseCase: any WireDriveCreateUseCaseProtocol
    ) {
        self.navigationPath = FilesNavigationItem.items(for: containerPath)
        self.rootPath = containerPath.components(separatedBy: "/").first ?? ""
        self.originalContainerPath = containerPath
        self.nodeID = nodeID
        self.nodeName = nodeName
        self.onFinish = onFinish
        self.nodesRepository = nodesRepository
        self.moveNodeUseCase = moveNodeUseCase
        self.createUseCase = createUseCase
        self.localAssetRepository = localAssetRepository
    }

    func makeView(path: String) -> some View {
        // swiftformat:disable:next redundantSelf
        WireMessagingUI.MoveToFolderPage(viewModel: self.makeViewModel(path: path))
    }

    private func makeViewModel(path: String) -> MoveToFolderPageViewModel {
        let nodesCollection = WireDriveNodesCollection()
        return MoveToFolderPageViewModel(
            containerPath: path,
            originalContainerPath: originalContainerPath,
            nodeID: nodeID,
            nodeName: nodeName,
            onNavigate: { [weak self] path in
                self?.navigationPath = MoveToFolderViewModel.FilesNavigationItem.items(for: path)
            },
            onFinish: { [weak self] in
                self?.onFinish()
            },
            nodesCollection: nodesCollection,
            fetchNodesUseCase: WireDriveFetchNodesUseCase(
                state: nodesCollection,
                configuration: .moveToFolder(root: path),
                repository: nodesRepository
            ),
            moveNodeUseCase: moveNodeUseCase,
            createFolderUseCase: createFolderUseCase
        )
    }

    private static func navigationPath(_ path: String) -> [String] {
        Array(path.components(separatedBy: "/").dropFirst())
    }
}

// MARK: - MockMoveToFolderViewModel

@MainActor
final class MockMoveToFolderViewModel: MoveToFolderViewModelProtocol {

    let rootPath: String

    @Published var navigationPath: [MoveToFolderViewModel.FilesNavigationItem]

    init(containerPath: String) {
        self.navigationPath = MoveToFolderViewModel.FilesNavigationItem.items(for: containerPath)
        self.rootPath = containerPath.components(separatedBy: "/").first ?? ""
    }

    func makeView(path: String) -> some View {
        WireMessagingUI.MoveToFolderPage(
            viewModel: MockMoveToFolderPageViewModel(
                title: "Files",
                content: .initialLoad,
                moveButtonState: .disabled,
                isNewFolderEnabled: false,
                navigationMenuOptions: []
            )
        )
    }

    private static func navigationPath(_ path: String) -> [String] {
        Array(path.components(separatedBy: "/").dropFirst())
    }
}
