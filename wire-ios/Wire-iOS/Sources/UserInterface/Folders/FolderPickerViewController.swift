//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireCommonComponents
import WireDataModel
import WireDesign

// MARK: - FolderPickerViewControllerDelegate

protocol FolderPickerViewControllerDelegate: AnyObject {
    func didPickFolder(_ folder: LabelType, for conversation: ZMConversation)
}

// MARK: - FolderPickerViewController

final class FolderPickerViewController: UIViewController {
    // MARK: Lifecycle

    init(conversation: ZMConversation, directory: ConversationDirectoryType) {
        self.conversation = conversation
        self.conversationDirectory = directory

        super.init(nibName: nil, bundle: nil)

        loadFolders()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var delegate: FolderPickerViewControllerDelegate?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavbar()
        configureSubviews()
        configureConstraints()
    }

    // MARK: Private

    private var conversationDirectory: ConversationDirectoryType
    private var items: [LabelType] = []
    private let conversation: ZMConversation
    private let hintLabel = DynamicFontLabel(
        fontSpec: .mediumSemiboldFont,
        color: SemanticColors.Label.textDefault
    )
    private let collectionViewLayout = UICollectionViewFlowLayout()

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)

    private func configureNavbar() {
        let navigationTitleLabel = DynamicFontLabel(
            text: L10n.Localizable.Folder.Picker.title.capitalized,
            fontSpec: .headerSemiboldFont,
            color: SemanticColors.Label.textDefault
        )

        let newFolderItem = UIBarButtonItem(
            icon: .plus,
            target: self,
            action: #selector(createNewFolder)
        )
        newFolderItem.accessibilityIdentifier = "button.newfolder.create"

        navigationItem.titleView = navigationTitleLabel
        navigationItem.leftBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Localizable.General.close)

        navigationItem.rightBarButtonItem = newFolderItem
    }

    private func loadFolders() {
        items = conversationDirectory.allFolders
        hintLabel.isHidden = !items.isEmpty
    }

    private func configureSubviews() {
        hintLabel.text = L10n.Localizable.Folder.Picker.Empty.hint
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = SemanticColors.View.backgroundDefault
        collectionView.alwaysBounceVertical = true

        collectionViewLayout.minimumLineSpacing = 0

        CheckmarkCell.register(in: collectionView)
    }

    private func configureConstraints() {
        view.addSubview(collectionView)
        view.addSubview(hintLabel)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fitIn(view: view)

        NSLayoutConstraint.activate([
            hintLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            hintLabel.trailingAnchor
                .constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            hintLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc
    private func createNewFolder() {
        let folderCreation = FolderCreationController(conversation: conversation, directory: conversationDirectory)
        folderCreation.delegate = self
        navigationController?.pushViewController(folderCreation, animated: true)
    }
}

// MARK: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

extension FolderPickerViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)
        let item = items[indexPath.row]
        cell.title = item.name
        cell.showSeparator = indexPath.row < (items.count - 1)
        if let folder = conversation.folder {
            cell.showCheckmark = (folder.remoteIdentifier == item.remoteIdentifier)
        } else {
            cell.showCheckmark = false
        }

        return cell
    }

    private func pickFolder(_ folder: LabelType) {
        delegate?.didPickFolder(folder, for: conversation)
        dismissIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let selectedItem = items[indexPath.row]
        pickFolder(selectedItem)
    }

    // MARK: Layout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 56)
    }
}

// MARK: FolderCreationControllerDelegate

extension FolderPickerViewController: FolderCreationControllerDelegate {
    func folderController(_ controller: FolderCreationController, didCreateFolder folder: LabelType) {
        pickFolder(folder)
    }
}
