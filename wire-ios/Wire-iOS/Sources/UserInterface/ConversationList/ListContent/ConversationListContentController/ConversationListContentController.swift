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

import DifferenceKit
import UIKit
import WireConversationListUI
import WireDataModel
import WireDesign
import WireMainNavigationUI
import WireSyncEngine

private let CellReuseIdConnectionRequests = "CellIdConnectionRequests"
private let CellReuseIdConversation = "CellId"

final class ConversationListContentController: UICollectionViewController {

    typealias ConversationListCoordinator = AnyConversationListCoordinator<
        ZMConversation,
        ZMConversationMessage
    >
    private let conversationListCoordinator: ConversationListCoordinator
    private let mainCoordinator: any MainCoordinatorProtocol

    private(set) weak var zClientViewController: ZClientViewController?

    weak var contentDelegate: ConversationListContentDelegate?
    let listViewModel: ConversationListViewModel
    private var focusOnNextSelection = false
    private var animateNextSelection = false
    private weak var scrollToMessageOnNextSelection: ZMConversationMessage?
    private let layoutCell = ConversationListCell()
    var startCallController: ConversationCallController?
    private var emptySearchPlaceholderView: UIStackView!
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private var token: NSObjectProtocol?

    let userSession: UserSession

    init<ConversationListCoordinator>(
        userSession: UserSession,
        conversationListCoordinator: ConversationListCoordinator,
        mainCoordinator: any MainCoordinatorProtocol,
        zClientViewController: ZClientViewController?
    ) where
    ConversationListCoordinator: ConversationListCoordinatorProtocol,
    ConversationListCoordinator.ConversationModel == ZMConversation,
    ConversationListCoordinator.ConversationMessageModel == ZMConversationMessage {

        self.userSession = userSession
        self.conversationListCoordinator = .init(conversationListCoordinator: conversationListCoordinator)
        self.mainCoordinator = mainCoordinator
        self.zClientViewController = zClientViewController

        let flowLayout = BoundsAwareFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero
        listViewModel = .init(userSession: userSession)
        super.init(collectionViewLayout: flowLayout)

        registerSectionHeader()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        super.loadView()

        listViewModel.delegate = self
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // viewWillAppear: can get called also when dismissing the controller above this one.
        // The self user might not be there anymore in some cases, e.g. when logging out
        guard SelfUser.provider != nil else { return }

        updateVisibleCells()
        emptySearchPlaceholderView.isHidden = true

        scrollToCurrentSelection(animated: false)

        token = NotificationCenter.default.addObserver(forName: .activeMediaPlayerChanged, object: nil, queue: .main) { [weak self] _ in
            self?.activeMediaPlayerChanged()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let token {
            NotificationCenter.default.removeObserver(token)
            self.token = nil
        }
    }

    override func viewDidLoad() {
        setupEmptyPlaceholder()
    }

    private func activeMediaPlayerChanged() {
        DispatchQueue.main.async {
            for cell in self.collectionView.visibleCells {
                (cell as? ConversationListCell)?.updateAppearance()
            }
        }
    }

    func reload() {
        collectionView.reloadData()
        ensureCurrentSelection()

        emptySearchPlaceholderView.isHidden = listViewModel.appliedSearchText.isEmpty || !listViewModel.isEmptyList

        // we MUST call layoutIfNeeded here because otherwise bad things happen when we close the archive, reload the conv
        // and then unarchive all at the same time
        view.layoutIfNeeded()
    }

    func updateVisibleCells() {
        for cell in collectionView.visibleCells {
            (cell as? ConversationListCell)?.updateAppearance()
        }
    }

    private func setupViews() {
        collectionView.register(ConnectRequestsCell.self, forCellWithReuseIdentifier: CellReuseIdConnectionRequests)
        collectionView.register(ConversationListCell.self, forCellWithReuseIdentifier: CellReuseIdConversation)

        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.contentInset = .zero
        collectionView.contentInset.top = -20
        collectionView.delaysContentTouches = false
        collectionView.accessibilityIdentifier = "conversation list"
        collectionView.backgroundColor = .clear
        clearsSelectionOnViewWillAppear = false
    }

    private func setupEmptyPlaceholder() {
        // Check if iPad
        let titleLabel = DynamicFontLabel(
            text: L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Subheadline.phone,
            style: .body1,
            color: ColorTheme.Base.secondaryText
        )

        let newConversationButton = DynamicFontButton(style: .body1)
        newConversationButton.setTitleColor(ColorTheme.Base.primary, for: .normal)

        let image = UIImage.imageForIcon(.plus, size: StyleKitIcon.Size.tiny.rawValue, color: ColorTheme.Backgrounds.background)
        let newIcon = createRoundIconImage(icon: image, iconSize: 10, backgroundColor: ColorTheme.Base.primary, imageSize: 20)

        let spacing: CGFloat = 10
        newConversationButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2, bottom: 0, right: spacing / 2)
        newConversationButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: -spacing / 2)

        newConversationButton.setImage(newIcon, for: .normal)
        newConversationButton.setBackgroundImageColor(ColorTheme.Backgrounds.background, for: .normal)
        newConversationButton.layer.cornerRadius = 18
        newConversationButton.layer.masksToBounds = true

        newConversationButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 42, bottom: 10, right: 42)
        newConversationButton.setTitle(L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Button.phone , for: .normal)
        newConversationButton.accessibilityIdentifier = "new-conversation.button"

        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        emptySearchPlaceholderView = UIStackView(arrangedSubviews: [titleLabel, newConversationButton])
        emptySearchPlaceholderView.axis = .vertical
        emptySearchPlaceholderView.spacing = 15
        emptySearchPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        emptySearchPlaceholderView.alignment = .center
        emptySearchPlaceholderView.distribution = .equalSpacing
        view.addSubview(emptySearchPlaceholderView)
        NSLayoutConstraint.activate([

            emptySearchPlaceholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptySearchPlaceholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptySearchPlaceholderView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            emptySearchPlaceholderView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: emptySearchPlaceholderView.trailingAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: emptySearchPlaceholderView.bottomAnchor, multiplier: 1),

            emptySearchPlaceholderView.widthAnchor.constraint(lessThanOrEqualToConstant: 272)
        ])
    }

    func createRoundIconImage(icon: UIImage, iconSize: CGFloat, backgroundColor: UIColor, imageSize: CGFloat) -> UIImage? {
        // Create a UIView with a circular shape
        let view = UIView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = imageSize / 2
        view.clipsToBounds = true

        // Create an UIImageView for the icon and center it in the view
        let iconImageView = UIImageView(image: icon.withRenderingMode(.alwaysTemplate))
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.frame = CGRect(x: (imageSize - iconSize) / 2, y: (imageSize - iconSize) / 2, width: iconSize, height: iconSize)
        view.addSubview(iconImageView)

        // Render the view into a UIImage
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    // MARK: - section header

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let section = indexPath.section

            if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier, for: indexPath) as? ConversationListHeaderView {
                header.title = listViewModel.sectionHeaderTitle(sectionIndex: section)?.uppercased()

                header.folderBadge = listViewModel.folderBadge(at: section)

                header.collapsed = listViewModel.collapsed(at: section)

                header.tapHandler = {[weak self] collapsed in
                    self?.listViewModel.setCollapsed(sectionIndex: section, collapsed: collapsed)
                }

                return header
            } else {
                fatal("Unknown supplementary view for \(kind)")
            }
        default:
            fatal("No supplementary view for \(kind)")
        }
    }

    private func registerSectionHeader() {
        collectionView?.register(ConversationListHeaderView.self, forSupplementaryViewOfKind:
            UICollectionView.elementKindSectionHeader, withReuseIdentifier: ConversationListHeaderView.reuseIdentifier)

    }

    /// ensures that the list selection state matches that of the model.
    func ensureCurrentSelection() {
        guard let selectedItem = listViewModel.selectedItem else { return }

        let selectedIndexPaths = collectionView.indexPathsForSelectedItems

        if let currentIndexPath = listViewModel.indexPath(for: selectedItem) {
            if selectedIndexPaths?.contains(currentIndexPath) == false {
                // This method doesn't trigger any delegate callbacks, so no worries about special handling
                collectionView.selectItem(at: currentIndexPath, animated: false, scrollPosition: [])
            }
        } else {
            // Current selection is no longer available so we should unload the conversation view
            listViewModel.select(itemToSelect: nil)
        }
    }

    func scrollToCurrentSelection(animated: Bool) {
        guard let selectedItem = listViewModel.selectedItem,
            let selectedIndexPath = listViewModel.indexPath(for: selectedItem),
            // Check if indexPath is valid for the collection view
            collectionView.numberOfSections > selectedIndexPath.section,
            collectionView.numberOfItems(inSection: selectedIndexPath.section) > selectedIndexPath.item else {
                return
        }

        if !collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
            collectionView.scrollToItem(at: selectedIndexPath, at: [], animated: animated)
        }
    }

    @discardableResult
    func selectInboxAndFocus(onView focus: Bool) -> Bool {
        // If there is anything in the inbox, select it
        if listViewModel.numberOfItems(inSection: 0) > 0 {

            focusOnNextSelection = focus
            selectModelItem(ConversationListViewModel.contactRequestsItem)
            return true
        }
        return false
    }

    func select(_ conversation: ZMConversation?, scrollTo message: ZMConversationMessage?, focusOnView focus: Bool, animated: Bool) -> Bool {
        focusOnNextSelection = focus

        animateNextSelection = animated
        scrollToMessageOnNextSelection = message

        // Tell the model to select the item
        return selectModelItem(conversation)
    }

    @discardableResult
    func selectModelItem(_ itemToSelect: ConversationListItem?) -> Bool {
        listViewModel.select(itemToSelect: itemToSelect)
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        selectionFeedbackGenerator.prepare()
        return true
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        selectionFeedbackGenerator.selectionChanged()
        openConversation(conversationListItem: listViewModel.item(for: indexPath))
    }

    // MARK: preview

    private func openConversation(conversationListItem: ConversationListItem?) {
        focusOnNextSelection = true
        animateNextSelection = true
        selectModelItem(conversationListItem)
    }

    // MARK: context menu

    override func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {

        guard let conversation = listViewModel.item(for: indexPath) as? ZMConversation else {
                return nil
        }

        let previewProvider: UIContextMenuContentPreviewProvider = {
            ConversationPreviewViewController(
                conversation: conversation,
                presentingViewController: self,
                sourceView: collectionView.cellForItem(at: indexPath)!,
                userSession: self.userSession,
                mainCoordinator: self.mainCoordinator
            )
        }

        let actionProvider: UIContextMenuActionProvider = { _ in
            let actions = conversation.listActions.map { action in
                UIAction(title: action.title, image: nil) { _ in
                    let actionController = ConversationActionController(
                        conversation: conversation,
                        target: self,
                        sourceView: collectionView.cellForItem(at: indexPath)!,
                        userSession: self.userSession
                    )
                    actionController.handleAction(action)
                }
            }

            return UIMenu(title: conversation.displayNameWithFallback, children: actions)
        }

        return UIContextMenuConfiguration(
            identifier: indexPath as NSIndexPath,
            previewProvider: .none,
            actionProvider: actionProvider
        )
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return listViewModel.sectionCount
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listViewModel.numberOfItems(inSection: section)
    }

    override func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = listViewModel.item(for: indexPath)
        let cell: UICollectionViewCell

        if item is ConversationListConnectRequestsItem,
            let labelCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdConnectionRequests, for: indexPath) as? ConnectRequestsCell {
            cell = labelCell
        } else if item is ZMConversation,
            let listCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdConversation, for: indexPath) as? ConversationListCell {

            listCell.delegate = self
            listCell.mutuallyExclusiveSwipeIdentifier = "ConversationList"
            listCell.conversation = item as? ZMConversation

            cell = listCell
        } else {
            fatal("Unknown cell type")
        }

        if let cell = cell as? SectionListCellType {
            cell.sectionName = listViewModel.sectionCanonicalName(of: indexPath.section)
            cell.obfuscatedSectionName = listViewModel.obfuscatedSectionName(of: indexPath.section)
            cell.cellIdentifier = "conversation_list_cell"
        }

        cell.autoresizingMask = .flexibleWidth
        return cell
    }
}

extension ConversationListContentController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: listViewModel.sectionHeaderVisible(section: section) ? CGFloat.ConversationListSectionHeader.height : 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layoutCell.size(inCollectionViewSize: collectionView.bounds.size)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension ConversationListContentController: ConversationListViewModelDelegate {

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSection section: Int) {
        guard let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section)) as? ConversationListHeaderView else {
            return
        }

        header.folderBadge = listViewModel.folderBadge(at: section)
    }

    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: ConversationListItem?) {
        defer {
            scrollToMessageOnNextSelection = nil
            focusOnNextSelection = false
        }

        guard let item else {
            // Deselect all items in the collection view
            let indexPaths = collectionView.indexPathsForSelectedItems
            (indexPaths as NSArray?)?.enumerateObjects({ obj, _, _ in
                if let obj = obj as? IndexPath {
                    self.collectionView.deselectItem(at: obj, animated: false)
                }
            })
            // TODO: [WPB-11609] still needed? (iPhone and iPad)
            // zClientViewController?.loadPlaceholderConversationController(animated: true)
            zClientViewController?.transitionToList(animated: true, completion: nil)

            return
        }

        Task {
            if let conversation = item as? ZMConversation {
                if let message = scrollToMessageOnNextSelection {
                    await conversationListCoordinator.showConversation(conversation: conversation, scrolledTo: message)
                } else {
                    await conversationListCoordinator.showConversation(conversation: conversation)
                }
                contentDelegate?.conversationList(self, didSelect: conversation, focusOnView: !focusOnNextSelection)
            } else if item is ConversationListConnectRequestsItem {
                zClientViewController?.loadIncomingContactRequestsAndFocus(onView: focusOnNextSelection, animated: true)
            } else {
                assertionFailure("Invalid item in conversation list view model!!")
            }
            // Make sure the correct item is selected in the list, without triggering a collection view callback
            ensureCurrentSelection()
        }
    }

    func listViewModelShouldBeReloaded() {
        reload()
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: Int, animated: Bool) {
        let reloadClosure = {
            self.collectionView.reloadSections(IndexSet(integer: section))
            self.ensureCurrentSelection()
        }

        if animated {
            reloadClosure()
        } else {
            UIView.performWithoutAnimation {
                reloadClosure()
            }
        }
    }

    func listViewModel(_ model: ConversationListViewModel?, didChangeFolderEnabled folderEnabled: Bool) {}

    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C?) -> Void
    ) {
        collectionView.reload(using: stagedChangeset, interrupt: interrupt, setData: setData)
    }
}

// MARK: iOS 12- peek pop
extension ConversationListContentController: UIViewControllerPreviewingDelegate {

    @available(iOS, introduced: 9.0, deprecated: 13.0, renamed: "UIContextMenuInteraction")
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let previewViewController = viewControllerToCommit as? ConversationPreviewViewController else { return }

        openConversation(conversationListItem: previewViewController.conversation)
    }

    @available(iOS, introduced: 9.0, deprecated: 13.0, renamed: "UIContextMenuInteraction")
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location),
            let layoutAttributes = collectionView.layoutAttributesForItem(at: indexPath)
            else {
                return nil
        }

        guard let conversation = listViewModel.item(for: indexPath) as? ZMConversation else {
            return nil
        }

        previewingContext.sourceRect = layoutAttributes.frame

        return ConversationPreviewViewController(
            conversation: conversation,
            presentingViewController: self,
            sourceView: collectionView.cellForItem(at: indexPath)!,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
    }
}

extension ConversationListContentController: ConversationListCellDelegate {
    func indexPath(for cell: ConversationListCell) -> IndexPath? {
        return collectionView.indexPath(for: cell)
    }

    func conversationListCellOverscrolled(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation as? ZMConversation else {
            return
        }

        contentDelegate?.conversationListContentController(self, wantsActionMenuFor: conversation, fromSourceView: cell)
    }

    func conversationListCellJoinCallButtonTapped(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation as? ZMConversation else { return }

        startCallController = ConversationCallController(conversation: conversation, target: self)
        startCallController?.joinCall()
    }
}
