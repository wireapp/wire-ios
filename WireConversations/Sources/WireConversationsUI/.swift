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

package import SwiftUI
import UIKit
package import WireConversationsAPI
import WireReusableUIComponents

class WireConversationChannelCreationFormViewController: UIViewController {

    private let onNext: @Sendable (WireConversationChannelCreationSettings) -> Void
    private var values: ConversationCreationValues

    private lazy var hostingController: UIHostingController<WireConversationChannelCreationForm> = {
        let rootView = WireConversationChannelCreationForm(
            onFormValidityUpdate: { formIsValid in
                Task { @MainActor [weak self] in
                    self?.onFormValidityUpdate(formIsValid: formIsValid)
                }
            }
        )
        return UIHostingController(rootView: rootView)
    }()

    @MainActor var channelCreationSettings: WireConversationChannelCreationSettings {
        hostingController.rootView.channelCreationSettings
    }

    package init(onNext: @escaping @Sendable (WireConversationChannelCreationSettings) -> Void) {
        self.onNext = onNext
        self.values = ConversationCreationValues(
            encryptionProtocol: userSession.defaultProtocol,
            selfUser: userSession.selfUser
        )
        super.init()
    }

    @available(*, unavailable)
    @MainActor @preconcurrency
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    package override func viewDidLoad() {
        super.viewDidLoad()

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    package override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = navigationBarTitle {
            setupNavigationBarTitle(title)
        }

        setupNavigationBarButtonItems()
    }

    private func setupNavigationBarButtonItems() {
        let backButton = UIBarButtonItem.createNavigationLeftBarButtonItem(
            title: L10n.Localizable.Conversation.Create.Channel.back,
            action: UIAction { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
        )
        backButton.accessibilityLabel = L10n.Accessibility.Conversation.Create.Channel.back
        backButton.accessibilityIdentifier = "back"
        navigationItem.leftBarButtonItem = backButton

        let nextButton = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: L10n.Localizable.Conversation.Create.Channel.next,
            action: UIAction { [weak self] _ in
                guard let self else { return }
                onNext(channelCreationSettings)
            }
        )
        nextButton.accessibilityIdentifier = "next"
        navigationItem.rightBarButtonItem = nextButton
    }

    private var navigationBarTitle: String? {
        L10n.Localizable.Conversation.Create.Channel.title
    }

    private func onFormValidityUpdate(formIsValid: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = formIsValid
    }
}
