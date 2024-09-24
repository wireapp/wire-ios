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
import WireDesign
import WireSyncEngine

protocol FolderCreationControllerDelegate: AnyObject {

    func folderController(
        _ controller: FolderCreationController,
        didCreateFolder folder: LabelType)

}

final class FolderCreationController: UIViewController {

    private let collectionViewController = SectionCollectionViewController()

    private lazy var nameSection: FolderCreationNameSectionController = {
        return FolderCreationNameSectionController(delegate: self,
                                                   conversationName: conversation.displayNameWithFallback)
    }()

    private var folderName: String = ""
    private var conversation: ZMConversation
    private var conversationDirectory: ConversationDirectoryType

    fileprivate var navBarBackgroundView = UIView()

    weak var delegate: FolderCreationControllerDelegate?

    init(conversation: ZMConversation, directory: ConversationDirectoryType) {
        self.conversation = conversation
        self.conversationDirectory = directory
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault

        setupViews()

        // try to overtake the first responder from the other view
        if UIResponder.currentFirst != nil {
            nameSection.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameSection.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    private func setupViews() {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: if keyboard is open, it should scroll.
        let collectionView = UICollectionView(forGroupedSections: ())

        collectionView.contentInsetAdjustmentBehavior = .never

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        collectionViewController.collectionView = collectionView
        collectionViewController.sections = [nameSection]

        navBarBackgroundView.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(navBarBackgroundView)

        navBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            navBarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }

    private func setupNavigationBar() {
        typealias FolderCreationName = L10n.Localizable.Folder.Creation.Name

        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
                self?.presentingViewController?.dismiss(animated: true)
            }, accessibilityLabel: L10n.Localizable.General.close)
        }

        let nextButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: FolderCreationName.Button.create,
            action: UIAction { [weak self] _ in
                self?.tryToProceed()
            })

        nextButtonItem.accessibilityIdentifier = "button.newfolder.create"
        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = false

        setupNavigationBarTitle(FolderCreationName.title)
        navigationItem.rightBarButtonItem = nextButtonItem
    }

    func proceedWith(value: SimpleTextField.Value) {
        switch value {
        case let .error(error):
            print(error)
        case let .valid(name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            nameSection.resignFirstResponder()
            folderName = trimmed

            if let folder = ZMUserSession.shared()?.conversationDirectory.createFolder(folderName) {
                self.delegate?.folderController(self, didCreateFolder: folder)
            }
        }
    }

    fileprivate func tryToProceed() {
        guard let value = nameSection.value else { return }
        proceedWith(value: value)
    }
}

// MARK: - SimpleTextFieldDelegate

extension FolderCreationController: SimpleTextFieldDelegate {

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {

        switch value {
        case .error: navigationItem.rightBarButtonItem?.isEnabled = false
        case .valid(let text): navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
        }

    }

    func textFieldReturnPressed(_ textField: SimpleTextField) {
        tryToProceed()
    }

    func textFieldDidBeginEditing(_ textField: SimpleTextField) {

    }

    func textFieldDidEndEditing(_ textField: SimpleTextField) {

    }
}
