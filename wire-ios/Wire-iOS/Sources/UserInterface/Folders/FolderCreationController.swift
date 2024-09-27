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

// MARK: - FolderCreationControllerDelegate

protocol FolderCreationControllerDelegate: AnyObject {
    func folderController(
        _ controller: FolderCreationController,
        didCreateFolder folder: LabelType
    )
}

// MARK: - FolderCreationController

final class FolderCreationController: UIViewController {
    // MARK: Lifecycle

    init(conversation: ZMConversation, directory: ConversationDirectoryType) {
        self.conversation = conversation
        self.conversationDirectory = directory
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var delegate: FolderCreationControllerDelegate?

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

    func proceedWith(value: SimpleTextField.Value) {
        switch value {
        case let .error(error):
            print(error)
        case let .valid(name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            nameSection.resignFirstResponder()
            folderName = trimmed

            if let folder = ZMUserSession.shared()?.conversationDirectory.createFolder(folderName) {
                delegate?.folderController(self, didCreateFolder: folder)
            }
        }
    }

    // MARK: Fileprivate

    fileprivate var navBarBackgroundView = UIView()

    fileprivate func tryToProceed() {
        guard let value = nameSection.value else { return }
        proceedWith(value: value)
    }

    // MARK: Private

    private let collectionViewController = SectionCollectionViewController()

    private lazy var nameSection = FolderCreationNameSectionController(
        delegate: self,
        conversationName: conversation
            .displayNameWithFallback
    )

    private var folderName = ""
    private var conversation: ZMConversation
    private var conversationDirectory: ConversationDirectoryType

    private func setupViews() {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: if keyboard is open, it should scroll.
        let collectionView = UICollectionView(forGroupedSections: ())

        collectionView.contentInsetAdjustmentBehavior = .never

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
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
            navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeTopAnchor),
        ])
    }

    private func setupNavigationBar() {
        typealias FolderCreationName = L10n.Localizable.Folder.Creation.Name
        navigationController?.navigationBar.tintColor = SemanticColors.Label.textDefault
        navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes()

        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
                self?.presentingViewController?.dismiss(animated: true)
            }, accessibilityLabel: L10n.Localizable.General.close)
        }

        let nextButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: FolderCreationName.Button.create,
            action: UIAction { [weak self] _ in
                self?.tryToProceed()
            }
        )

        nextButtonItem.accessibilityIdentifier = "button.newfolder.create"
        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = false

        setupNavigationBarTitle(FolderCreationName.title)
        navigationItem.rightBarButtonItem = nextButtonItem
    }
}

// MARK: SimpleTextFieldDelegate

extension FolderCreationController: SimpleTextFieldDelegate {
    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {
        switch value {
        case .error: navigationItem.rightBarButtonItem?.isEnabled = false
        case let .valid(text): navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
        }
    }

    func textFieldReturnPressed(_: SimpleTextField) {
        tryToProceed()
    }

    func textFieldDidBeginEditing(_: SimpleTextField) {}

    func textFieldDidEndEditing(_: SimpleTextField) {}
}
