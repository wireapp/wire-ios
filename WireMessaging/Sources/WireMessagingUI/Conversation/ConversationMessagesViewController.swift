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
package import SwiftUI

package final class ConversationMessagesViewController: UIViewController {

    typealias DataSource = UICollectionViewDiffableDataSource<ConversationSection, ConversationElement>

    let viewModel: any ConversationMessagesViewModelProtocol

    private var collectionView: UICollectionView!
    private var dataSource: DataSource!

    var cancellables = Set<AnyCancellable>()

    package init(viewModel: any ConversationMessagesViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    package required init?(coder: NSCoder) {
        fatalError()
    }

    private var observeTask: Task<Void, Never>?

    package override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupDataSource()

        observeTask = Task { [weak self] in
            await self?.observeUpdates()
        }

        viewModel.onViewReady()
    }

    package override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        observeTask?.cancel()
        observeTask = nil
        viewModel.onWillDisappear()
    }

    private func observeUpdates() async {
        let stream = await viewModel.makeUpdatesStream()
        for await update in stream {
            switch update {
            case let .initiallyLoaded(snapshot):
                await dataSource.apply(snapshot)
                scrollToLastItem(animated: false)
            case let .messageAdded(snapshot):
                await dataSource.apply(snapshot)
                scrollToLastItem()
            }
        }
    }

    private let reuseIdentifier: String = "MessageCell"

    private func setupCollectionView() {
        let layout = createLayout()

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true

        collectionView
            .register(
                UICollectionViewCell.self,
                forCellWithReuseIdentifier: reuseIdentifier
            )

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupDataSource() {
        dataSource =
            DataSource(
                collectionView: collectionView
            ) { [weak self] collectionView, indexPath, message -> UICollectionViewCell? in
                guard let self else { return UICollectionViewCell() }
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: reuseIdentifier,
                    for: indexPath
                )

                setContent(cell: cell, message: message)

                return cell
            }
    }

    private func setContent(cell: UICollectionViewCell, message: ConversationElement) {
        switch message {
        case let .text(viewModel):
            let config = UIHostingConfiguration {
                TextMessageView(viewModel: viewModel)
            }
            cell.contentConfiguration = config
        }
    }

    func scrollToLastItem(animated: Bool = true) {
        let lastItem = max(collectionView.numberOfItems(inSection: 0) - 1, 0)

        guard lastItem > 0 else { return }

        let indexPath = IndexPath(item: lastItem, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
}

import WireMessagingDomainSupport

private struct ConversationMessagesViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ConversationMessagesViewController {
        ConversationMessagesViewController(
            viewModel: ConversationMessagesViewModel(
                dataSource: ConversationDataSource(
                    loadMessagesUseCase: MockLoadConversationMessagesUseCaseProtocol(),
                    monitorMessagesUseCase: MockMonitorMessagesUseCaseProtocol(),
                    senderNameObserverProvider: AnySenderNameObserverProvider { _ in
                        nil
                    }
                )
            )
        )
    }

    func updateUIViewController(_ uiViewController: ConversationMessagesViewController, context: Context) {}
}

#Preview {
    ConversationMessagesViewControllerPreview()
}
