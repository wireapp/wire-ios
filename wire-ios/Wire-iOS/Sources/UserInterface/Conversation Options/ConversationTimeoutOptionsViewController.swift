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
import WireDataModel
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

final class ConversationTimeoutOptionsViewController: UIViewController {

    private let conversation: ZMConversation
    private let viewModel: ConversationTimeoutOptionsViewModel
    private let userSession: ZMUserSession
    private var observerToken: Any!

    private let collectionViewLayout = UICollectionViewFlowLayout()

    private lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: collectionViewLayout)

    // MARK: - Initialization

    init(conversation: ZMConversation, userSession: ZMUserSession) {
        self.conversation = conversation
        self.viewModel = ConversationTimeoutOptionsViewModel(
            currentValue: conversation.messageDestructionTimeoutValue(for: .groupConversation)
        )
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
        self.observerToken = ConversationChangeInfo.add(observer: self, for: conversation)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let state = viewModel.state
        setupNavigationBarTitle(state.title)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: state.closeButtonAccessibilityLabel)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    private func configureSubviews() {

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = SemanticColors.View.backgroundDefault
        collectionView.alwaysBounceVertical = true

        collectionViewLayout.minimumLineSpacing = 0

        CheckmarkCell.register(in: collectionView)
        collectionView.register(
            SectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader"
        )

    }

    private func configureConstraints() {

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.fitIn(view: view)
    }

}

// MARK: - Table View

extension ConversationTimeoutOptionsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.state.options.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader",
            for: indexPath
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let option = viewModel.state.options[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)

        cell.title = option.title
        cell.disabled = !option.isEnabled
        cell.showCheckmark = option.isSelected
        cell.showSeparator = indexPath.row < (viewModel.state.options.count - 1)

        return cell
    }

    private func updateTimeout(_ timeout: MessageDestructionTimeoutValue) {
        let activityIndicator = BlockingActivityIndicator(view: view)
        let item = CancelableItem(delay: 0.4) {
            activityIndicator.start()
        }

        conversation.setMessageDestructionTimeout(timeout, in: userSession) { [weak self] result in
            guard let self else {
                return
            }

            item.cancel()
            activityIndicator.stop()

            if case let .failure(error) = result {
                handle(error: error)
            }
        }
    }

    private func handle(error _: Error) {
        let state = viewModel.state
        let controller = UIAlertController(
            title: state.connectionErrorTitle,
            message: state.connectionErrorMessage,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default
        ))
        controller.view.tintColor = SemanticColors.Label.textDefault
        present(controller, animated: true)
    }

    // MARK: Saving Changes

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let timeout = viewModel.timeoutToSave(forOptionAt: indexPath.row) else {
            return
        }

        updateTimeout(timeout)
    }

    // MARK: Layout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 32)
    }

}

extension ConversationTimeoutOptionsViewController: ZMConversationObserver {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.destructionTimeoutChanged else {
            return
        }
        viewModel.updateCurrentValue(
            conversation.messageDestructionTimeoutValue(for: .groupConversation)
        )
        collectionView.reloadData()
    }
}
