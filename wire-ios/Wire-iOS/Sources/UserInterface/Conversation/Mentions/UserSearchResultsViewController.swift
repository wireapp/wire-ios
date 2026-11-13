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
import WireLocators

protocol UserSearchResultsViewControllerDelegate: AnyObject {
    func didSelect(suggestion: MentionSuggestion)
}

enum MentionSuggestion {
    case everyone
    case user(UserType)
}

protocol Dismissable: AnyObject {
    func dismiss()
}

protocol KeyboardCollapseObserver: AnyObject {
    var isKeyboardCollapsed: Bool { get }
}

protocol UserList: AnyObject {
    var suggestions: [MentionSuggestion] { get set }
    var selectedSuggestion: MentionSuggestion? { get }

    func selectPreviousUser()
    func selectNextUser()
}

final class UserSearchResultsViewController: UIViewController, KeyboardCollapseObserver {

    var users: [UserType] {
        get {
            suggestions.compactMap {
                guard case let .user(user) = $0 else { return nil }
                return user
            }
        }
        set {
            suggestions = newValue.map(MentionSuggestion.user)
        }
    }

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private var searchResults: [MentionSuggestion] = [] {
        didSet {
            if !searchResults.isEmpty {
                collectionViewSelectedIndex = searchResults.count - 1
            } else {
                collectionViewSelectedIndex = .none
            }
        }
    }

    private let rowHeight: CGFloat = 56.0
    private let avatarSpacing: CGFloat = 56.0
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

    private(set) var isKeyboardCollapsed: Bool = true {
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
        collectionView.register(
            UserCell.self,
            forCellWithReuseIdentifier: UserCell.reuseIdentifier
        )
        collectionView.register(
            EveryoneMentionCell.self,
            forCellWithReuseIdentifier: EveryoneMentionCell.reuseIdentifier
        )
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
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func reloadTable(with results: [MentionSuggestion]) {
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

        // If there are more rows that can fix on screen, enable scroll.
        collectionView.isScrollEnabled = contentHeight > viewHeight

        // Push the rows down to be flush with the bottom of the view.
        let bottomInset = max(0, viewHeight - contentHeight)
        collectionView.contentInset = UIEdgeInsets(top: bottomInset, left: 0, bottom: 0, right: 0)
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

extension UserSearchResultsViewController: Dismissable {
    func dismiss() {
        view.isHidden = true
        collectionViewSelectedIndex = .none
    }
}

extension UserSearchResultsViewController: UserList {
    var selectedSuggestion: MentionSuggestion? {

        guard let collectionViewSelectedIndex else {
            return .none
        }

        return searchResults[collectionViewSelectedIndex]
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

    var suggestions: [MentionSuggestion] {
        get {
            searchResults.reversed()
        }

        set {
            reloadTable(with: newValue.reversed())
        }
    }
}

extension UserSearchResultsViewController: UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        searchResults.count
    }
}

extension UserSearchResultsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: rowHeight)
    }
}

extension UserSearchResultsViewController: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let suggestion = searchResults[indexPath.item]
        if case .everyone = suggestion {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EveryoneMentionCell.reuseIdentifier,
                for: indexPath
            ) as! EveryoneMentionCell
            cell.configure()
            cell.accessibilityHint = L10n.Accessibility.Conversation.MentionSuggestion.hint
            configureBackground(for: cell, at: indexPath)
            return cell
        }

        guard case let .user(user) = suggestion else { fatal("Unsupported mention suggestion") }
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
        cell.accessibilityHintOverride = L10n.Accessibility.Conversation.MentionSuggestion.hint

        configureBackground(for: cell, at: indexPath)

        cell.accessibilityIdentifier = Locators.ActiveConversationPage.userCellName.rawValue
        return cell
    }

    private func configureBackground(for cell: UICollectionViewCell, at indexPath: IndexPath) {
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
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelect(suggestion: searchResults[indexPath.item])
        dismiss()
    }
}

private final class EveryoneMentionCell: UICollectionViewCell {
    static let reuseIdentifier = "EveryoneMentionCell"

    private let iconView = UIImageView(image: UIImage(systemName: "person.3.fill"))
    private let titleLabel = DynamicFontLabel(
        fontSpec: .normalFont,
        color: SemanticColors.Label.textDefault
    )
    private let subtitleLabel = DynamicFontLabel(
        fontSpec: .smallFont,
        color: SemanticColors.Label.textDefault
    )

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.tintColor = SemanticColors.Icon.foregroundDefaultBlack
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "@all"
        subtitleLabel.text = L10n.Localizable.Conversation.InputBar.MentionAll.subtitle

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2
        labels.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        contentView.addSubview(labels)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            labels.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            labels.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            labels.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        isAccessibilityElement = true
        accessibilityLabel = "@all, \(L10n.Localizable.Conversation.InputBar.MentionAll.subtitle)"
        accessibilityIdentifier = "conversation.mention.everyone"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {}
}
