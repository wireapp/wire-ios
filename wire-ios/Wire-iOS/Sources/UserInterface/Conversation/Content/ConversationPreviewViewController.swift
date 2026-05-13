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

import UIKit
import WireMainNavigationUI
import WireMessagingDomain
import WireSyncEngine

final class ConversationPreviewViewController: UIViewController {

    var conversation: ZMConversation { viewModel.conversation }

    private let viewModel: ConversationPreviewViewModel
    let actionController: ConversationActionController
    fileprivate var contentViewController: ConversationContentViewController

    init(
        conversation: ZMConversation,
        presentingViewController: UIViewController,
        sourceView: UIView,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol,
        wireMessagingFactory: any WireMessagingFactoryProtocol
    ) {
        self.viewModel = ConversationPreviewViewModel(conversation: conversation)
        self.actionController = ConversationActionController(
            conversation: conversation,
            target: presentingViewController,
            sourceView: sourceView,
            userSession: userSession
        )

        self.contentViewController = ConversationContentViewController(
            conversation: conversation,
            mediaPlaybackManager: nil,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository,
            wireMessagingFactory: wireMessagingFactory
        )
        DeveloperToolsViewModel.context.currentConversation = conversation

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createViews()
        createConstraints()
    }

    func createViews() {
        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
        view.backgroundColor = contentViewController.tableView.backgroundColor
    }

    private func createConstraints() {
        guard let conversationView = contentViewController.view else { return }

        conversationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            conversationView.topAnchor.constraint(equalTo: view.topAnchor),
            conversationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            conversationView.leftAnchor.constraint(equalTo: view.leftAnchor),
            conversationView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    // MARK: Preview Actions

    @available(
        iOS,
        introduced: 9.0,
        deprecated: 13.0,
        message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction."
    )
    override var previewActionItems: [UIPreviewActionItem] {
        viewModel.state.actions.enumerated().map {
            makePreviewAction(index: $0.offset, action: $0.element)
        }
    }

    @available(
        iOS,
        introduced: 9.0,
        deprecated: 13.0,
        message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction."
    )
    private func makePreviewAction(index: Int, action: ConversationPreviewViewModel.PreviewAction) -> UIPreviewAction {
        .init(title: action.title, style: action.style.previewActionStyle) { [weak self] _, _ in
            guard let self else { return }
            handle(route: viewModel.routeForPreviewAction(at: index))
        }
    }

    private func handle(route: ConversationPreviewViewModel.Route) {
        switch route {
        case let .performConversationAction(action):
            actionController.handleAction(action)
        case .openConversation,
             .dismissPreview:
            break
        }
    }
}

private extension ConversationPreviewViewModel.ActionStyle {

    @available(
        iOS,
        introduced: 9.0,
        deprecated: 13.0,
        message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction."
    )
    var previewActionStyle: UIPreviewAction.Style {
        switch self {
        case .default:
            .default
        case .destructive:
            .destructive
        }
    }
}
