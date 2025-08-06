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

public import SwiftUI
import Combine

public final class ConversationMessagesViewController: UIViewController {

    typealias DataSource = UICollectionViewDiffableDataSource<MessagesSection, MessageType>

    let viewModel: any ConversationMessagesViewModelProtocol

    private var collectionView: UICollectionView!
    private var dataSource: DataSource!

    var cancellables = Set<AnyCancellable>()

    public init(viewModel: any ConversationMessagesViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupDataSource()

        Task {
            await self.observeUpdates()
        }

        viewModel.onViewReady()

    }

    private func observeUpdates() async {
        let stream = await viewModel.updatesStream()
        for await update in stream {
            switch update {
            case let .initiallyLoaded(snapshot):
                await dataSource.apply(snapshot)
            case let .messageAdded(snapshot):
                await dataSource.apply(snapshot)
            }
        }
    }

    private func setupCollectionView() {
        let layout = createLayout()

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true

        collectionView
            .register(
                MessageCollectionViewCell.self,
                forCellWithReuseIdentifier: MessageCollectionViewCell.reuseIdentifier
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
            DataSource(collectionView: collectionView) { collectionView, indexPath, message -> UICollectionViewCell? in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MessageCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as? MessageCollectionViewCell else {
                    return UICollectionViewCell
                    ()
                }

                cell.messageType = message

                return cell
            }
    }

}

private struct ConversationMessagesViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ConversationMessagesViewController {
        ConversationMessagesViewController(
            viewModel: ConversationMessagesViewModel(
                dataSource: ConversationMessagesDataSource()
            )
        )
    }

    func updateUIViewController(_ uiViewController: ConversationMessagesViewController, context: Context) {}
}

#Preview {
    ConversationMessagesViewControllerPreview()
}
