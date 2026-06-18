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

final class ConversationInactivityTimeoutOptionsViewController: UIViewController {

    private let conversation: ZMConversation
    private let collectionViewLayout = UICollectionViewFlowLayout()
    private lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: collectionViewLayout)

    init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        configureConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTitle("Auto-lock timeout")
    }

    private func configureSubviews() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = SemanticColors.View.backgroundDefault
        collectionView.alwaysBounceVertical = true
        collectionViewLayout.minimumLineSpacing = 0
        CheckmarkCell.register(in: collectionView)
    }

    private func configureConstraints() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fitIn(view: view)
    }

    private var currentTimeout: InactivityTimeout {
        guard let conversationID = conversation.remoteIdentifier else { return .thirtySeconds }
        return InactivityTimeout.stored(for: conversationID)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ConversationInactivityTimeoutOptionsViewController: UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        InactivityTimeout.allCases.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)
        let timeout = InactivityTimeout.allCases[indexPath.row]
        cell.title = timeout.displayString
        cell.showCheckmark = currentTimeout == timeout
        cell.showSeparator = indexPath.row < InactivityTimeout.allCases.count - 1
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let timeout = InactivityTimeout.allCases[indexPath.row]
        guard let conversationID = conversation.remoteIdentifier else { return }
        InactivityTimeout.store(timeout, for: conversationID)
        collectionView.reloadData()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 56)
    }
}
