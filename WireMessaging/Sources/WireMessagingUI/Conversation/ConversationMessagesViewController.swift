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

public final class ConversationMessagesViewController: UIViewController {
    
    let viewModel: any ConversationMessagesViewModelProtocol
    
    @MainActor
    var messages: [MessageType] = []
    
    enum Section {
        case main
    }
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, MessageType>!
    
    public init(viewModel: any ConversationMessagesViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupDataSource()
        
#if DEBUG
        generateMessages()
        simulateRandomUpdates()
#endif
        
        applySnapshot()

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
        dataSource = UICollectionViewDiffableDataSource<Section, MessageType>(collectionView: collectionView) { (collectionView, indexPath, message) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MessageCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as! MessageCollectionViewCell
            
            cell.messageType = self.messages[indexPath.row]

            return cell
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MessageType>()
        snapshot.appendSections([.main])
        snapshot.appendItems(messages)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
#if DEBUG
    func generateMessages() {
        let base = "This is a line. "
        messages = (0..<7).map { _ in
            let repeatCount = Int.random(in: 1...5)
            return .text(TextMessageViewModel(
                content: AttributedString(
                    stringLiteral: String(
                        repeating: base,
                        count: repeatCount
                    )),
                senderViewModel: Bool.random() ?
                SenderViewModel(state: .exists("Sender")) : SenderViewModel(state: .empty)
            ))
        }
    }
    
    @MainActor
    func simulateRandomUpdates() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                
                guard let message = self.messages.randomElement(),
                      case let .text(randomVM) = message else {
                    return
                }
                let base = "Updated line. "
                var repeatCount = Int.random(in: 1...6)
                DispatchQueue.main.async {
                    randomVM.content = AttributedString(
                        stringLiteral: String(repeating: base, count: repeatCount))
                    let updateSenderAttributed = AttributedString(stringLiteral: String(
                        repeating: "Updated Sender",
                        count: repeatCount
                    ))
                    randomVM.senderViewModel.state = Bool.random() ? SenderViewModel.State.exists(updateSenderAttributed) : SenderViewModel.State.empty
                    
                }
                
                guard let message = self.messages.randomElement(),
                      case let .text(randomVM2) = message else {
                    return
                }
                repeatCount = Int.random(in: 1...6)
                DispatchQueue.main.async {
                    randomVM2.content = AttributedString(
                        stringLiteral: String(repeating: base, count: repeatCount))
                    let updateSenderAttributed = AttributedString(stringLiteral: String(
                        repeating: "Updated Sender",
                        count: repeatCount
                    ))
                    randomVM2.senderViewModel.state = Bool.random() ? SenderViewModel.State.exists(updateSenderAttributed) : SenderViewModel.State.empty
                }
                
                
                guard let message = self.messages.randomElement(),
                      case let .text(randomVM3) = message else {
                    return
                }
                repeatCount = Int.random(in: 1...6)
                DispatchQueue.main.async {
                    randomVM3.content = AttributedString(
                        stringLiteral: String(repeating: base, count: repeatCount))
                    let updateSenderAttributed = AttributedString(stringLiteral: String(
                        repeating: "Updated Sender",
                        count: repeatCount
                    ))
                    randomVM3.senderViewModel.state = Bool.random() ? SenderViewModel.State.exists(updateSenderAttributed) : SenderViewModel.State.empty
                }
            }
        }
    }

#endif
}

private struct ConversationMessagesViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ConversationMessagesViewController {
        ConversationMessagesViewController(
            viewModel: ConversationMessagesViewModel()
        )
    }

    func updateUIViewController(_ uiViewController: ConversationMessagesViewController, context: Context) {}
}

#Preview {
    ConversationMessagesViewControllerPreview()
}
