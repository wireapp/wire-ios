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
import WireDataModel
import WireDesign

// MARK: - UserSearchResultsViewControllerDelegate

protocol UserSearchResultsViewControllerDelegate: AnyObject {
    func didSelect(user: UserType)
}

// MARK: - Dismissable

protocol Dismissable: AnyObject {
    func dismiss()
}

// MARK: - KeyboardCollapseObserver

protocol KeyboardCollapseObserver: AnyObject {
    var isKeyboardCollapsed: Bool { get }
}

// MARK: - UserList

protocol UserList: AnyObject {
    var users: [UserType] { get set }
    var selectedUser: UserType? { get }

    func selectPreviousUser()
    func selectNextUser()
}

// MARK: - UserSearchResultsViewController

final class UserSearchResultsViewController: UIViewController, KeyboardCollapseObserver {
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private var searchResults: [UserType] = [] {
        didSet {
            if !searchResults.isEmpty {
                collectionViewSelectedIndex = searchResults.count - 1
            } else {
                collectionViewSelectedIndex = .none
            }
        }
    }

    private lazy var collectionViewHeight: NSLayoutConstraint = collectionView.heightAnchor
        .constraint(equalToConstant: 0)
    private let rowHeight: CGFloat = 56.0
    private var isKeyboardCollapsedFirstCalled = true

    private var _collectionViewSelectedIndex: Int? = .none
    private var collectionViewSelectedIndex: Int? {
        get {
            _collectionViewSelectedIndex
        }
        set {
            if let newValue {
                _collectionViewSelectedIndex = min(searchResults.count - 1, max(0, newValue))
            } else {
                _collectionViewSelectedIndex = newValue
            }
        }
    }

    private(set) var isKeyboardCollapsed = true {
        didSet {
            guard oldValue != isKeyboardCollapsed || isKeyboardCollapsedFirstCalled else { return }
            collectionView.reloadData()

            isKeyboardCollapsedFirstCalled = false
        }
    }

    weak var delegate: UserSearchResultsViewControllerDelegate?

    private var keyboardObserver: KeyboardBlockObserver?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupConstraints()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        setupKeyboardObserver()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if collectionView.frame.size != view.bounds.size {
            collectionView.frame = view.bounds
            resizeTable()
        }
    }

    private func setupKeyboardObserver() {
        keyboardObserver = KeyboardBlockObserver { [weak self] info in
            guard let self else { return }
            if let isKeyboardCollapsed = info.isKeyboardCollapsed {
                self.isKeyboardCollapsed = isKeyboardCollapsed
            }
        }
    }

    private func setupCollectionView() {
        view.isHidden = true

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = SemanticColors.View.backgroundDefault

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView.collectionViewLayout = layout

        view.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        view.addSubview(collectionView)

        view.accessibilityIdentifier = "mentions.list.container"
        collectionView.accessibilityIdentifier = "mentions.list.collection"
    }

    private func setupConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionViewHeight,
        ])
    }

    @objc
    func reloadTable(with results: [UserType]) {
        searchResults = results
        resizeTable()

        collectionView.reloadData()
        collectionView.layoutIfNeeded()

        scrollToLastItem()

        if !results.isEmpty {
            show()
        } else {
            dismiss()
        }
    }

    private func resizeTable() {
        let viewHeight = view.bounds.size.height
        let contentHeight = CGFloat(searchResults.count) * rowHeight
        let minValue = min(viewHeight, contentHeight)
        collectionViewHeight.constant = minValue
        collectionView.isScrollEnabled = (contentHeight > viewHeight)

        if searchResults.count == 1 {
            let bottomInset = viewHeight - rowHeight
            collectionView.contentInset = UIEdgeInsets(top: bottomInset, left: 0, bottom: 0, right: 0)
        } else {
            collectionView.contentInset = .zero
        }
    }

    private func scrollToLastItem() {
        let firstMatchIndexPath = IndexPath(item: searchResults.count - 1, section: 0)

        if collectionView.containsCell(at: firstMatchIndexPath) {
            collectionView.scrollToItem(at: firstMatchIndexPath, at: .bottom, animated: false)
        }
    }

    func show() {
        view.isHidden = false
    }

    @objc
    dynamic func keyboardWillChangeFrame(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }
        resizeTable()
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.scrollToLastItem()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.reloadData()
        }
    }
}

// MARK: Dismissable

extension UserSearchResultsViewController: Dismissable {
    func dismiss() {
        view.isHidden = true
        collectionViewSelectedIndex = .none
    }
}

// MARK: UserList

extension UserSearchResultsViewController: UserList {
    var selectedUser: UserType? {
        guard let collectionViewSelectedIndex else {
            return .none
        }

        let bestSuggestion = searchResults[collectionViewSelectedIndex]

        return bestSuggestion
    }

    func selectNextUser() {
        guard let collectionViewSelectedIndex else { return }

        self.collectionViewSelectedIndex = collectionViewSelectedIndex + 1

        updateHighlightedItem()
    }

    func selectPreviousUser() {
        guard let collectionViewSelectedIndex else { return }

        self.collectionViewSelectedIndex = collectionViewSelectedIndex - 1

        updateHighlightedItem()
    }

    func updateHighlightedItem() {
        collectionView.reloadData()

        guard let collectionViewSelectedIndex else { return }

        collectionView.scrollToItem(
            at: IndexPath(item: collectionViewSelectedIndex, section: 0),
            at: .centeredVertically,
            animated: true
        )
    }

    var users: [UserType] {
        get {
            searchResults.reversed()
        }

        set {
            reloadTable(with: newValue.reversed())
        }
    }
}

// MARK: UICollectionViewDelegate

extension UserSearchResultsViewController: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchResults.count
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension UserSearchResultsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: rowHeight)
    }
}

// MARK: UICollectionViewDataSource

extension UserSearchResultsViewController: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let user = searchResults[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: UserCell.reuseIdentifier,
            for: indexPath
        ) as! UserCell
        if let selfUser = ZMUser.selfUser() {
            cell.configure(
                user: user,
                isSelfUserPartOfATeam: selfUser.hasTeam
            )
        } else {
            assertionFailure("ZMUser.selfUser() is nil")
        }
        cell.showSeparator = false
        cell.avatarSpacing = conversationHorizontalMargins.left

        // hightlight the lowest cell if keyboard is collapsed
        if isKeyboardCollapsed || UIDevice.current.userInterfaceIdiom == .pad {
            if indexPath.item == collectionViewSelectedIndex {
                cell.backgroundColor = SemanticColors.View.backgroundUserCellHightLighted
            } else {
                cell.backgroundColor = SemanticColors.View.backgroundUserCell
            }
        } else {
            cell.backgroundColor = SemanticColors.View.backgroundUserCell
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelect(user: searchResults[indexPath.item])
        dismiss()
    }
}
