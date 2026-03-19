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
import WireFoundation
import WireLogging
import WireMainNavigationUI
import WireMessagingDomain
import WireSyncEngine

protocol CollectionsViewControllerDelegate: AnyObject {
    func collectionsViewController(
        _ viewController: CollectionsViewController,
        performAction: MessageAction,
        onMessage: ZMConversationMessage
    )

    func collectionsViewControllerDidRequestOpenSearchFiles(
        _ viewController: CollectionsViewController
    )
}

final class CollectionsViewController: UIViewController {
    var onDismiss: ((CollectionsViewController) -> Void)?
    let sections: CollectionsSectionSet
    weak var delegate: CollectionsViewControllerDelegate?
    var isShowingSearchResults: Bool {
        !textSearchController.resultsView.isHidden
    }

    var shouldTrackOnNextOpen = false

    var currentTextSearchQuery: [String] {
        textSearchController.searchQuery?.components(separatedBy: .whitespacesAndNewlines) ?? []
    }

    private var contentView: CollectionsView! {
        view as? CollectionsView
    }

    private let messagePresenter: MessagePresenter
    private weak var selectedMessage: ZMConversationMessage? = .none

    private var imageMessages: [ZMConversationMessage] = []
    private var videoMessages: [ZMConversationMessage] = []
    private var linkMessages: [ZMConversationMessage] = []
    private var fileAndAudioMessages: [ZMConversationMessage] = []

    private var collection: AssetCollectionWrapper!

    private var lastLayoutSize: CGSize = .zero
    private var deletionDialogPresenter: DeletionDialogPresenter?

    let userSession: UserSession
    let mainCoordinator: AnyMainCoordinator
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    let conversationCreationRepository: any ConversationCreationRepositoryProtocol
    var collectionsSectionSet: [CollectionsSectionSet]
    let isCellsEnabled: Bool

    private var fetchingDone: Bool = false {
        didSet {
            if isViewLoaded {
                updateNoElementsState()
                contentView.collectionView.reloadData()
            }

            trackOpeningIfNeeded()
        }
    }

    private var inOverviewMode: Bool {
        sections == .all
    }

    private lazy var textSearchController = TextSearchViewController(
        conversation: collection.conversation,
        userSession: userSession
    )

    convenience init(
        conversation: ZMConversation,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) {
        let matchImages = CategoryMatch(including: .image, excluding: .GIF)
        let matchFiles = CategoryMatch(including: .file, excluding: .video)
        let matchVideo = CategoryMatch(including: .video, excluding: .none)
        let matchLink = CategoryMatch(including: .linkPreview, excluding: .none)

        let holder = AssetCollectionWrapper(
            conversation: conversation,
            matchingCategories: [matchImages, matchFiles, matchVideo, matchLink]
        )

        self.init(
            collection: holder,
            isCellsEnabled: conversation.isWireDriveEnabled,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
    }

    init(
        collection: AssetCollectionWrapper,
        sections: CollectionsSectionSet = .all,
        messages: [ZMConversationMessage] = [],
        isCellsEnabled: Bool,
        fetchingDone: Bool = false,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) {
        self.collection = collection
        self.sections = sections
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.conversationCreationRepository = conversationCreationRepository
        self.isCellsEnabled = isCellsEnabled

        self.collectionsSectionSet = isCellsEnabled ? CollectionsSectionSet
            .visibleWithSearchFiles : CollectionsSectionSet.visible

        switch sections {
        case CollectionsSectionSet.images:
            self.imageMessages = messages
        case CollectionsSectionSet.filesAndAudio:
            self.fileAndAudioMessages = messages
        case CollectionsSectionSet.videos:
            self.videoMessages = messages
        case CollectionsSectionSet.links:
            self.linkMessages = messages
        default: break
        }

        self.fetchingDone = fetchingDone
        self.messagePresenter = MessagePresenter(userSession: userSession)

        super.init(nibName: .none, bundle: .none)
        collection.assetCollectionDelegate.add(self)
        self.deletionDialogPresenter = DeletionDialogPresenter(sourceViewController: self)
    }

    deinit {
        collection.assetCollectionDelegate.remove(self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refetchCollection() {
        collection.assetCollectionDelegate.remove(self)
        imageMessages = []
        videoMessages = []
        linkMessages = []
        fileAndAudioMessages = []
        collection = AssetCollectionWrapper(
            conversation: collection.conversation,
            matchingCategories: collection.matchingCategories
        )
        collection.assetCollectionDelegate.add(self)
        contentView.collectionView.reloadData()
    }

    override func loadView() {
        view = CollectionsView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textSearchController.delegate = self
        contentView.constrainViews(searchViewController: textSearchController)

        messagePresenter.targetViewController = self
        messagePresenter.modalTargetController = self

        contentView.collectionView.delegate = self
        contentView.collectionView.dataSource = self
        contentView.collectionView.prefetchDataSource = self

        updateNoElementsState()

        NotificationCenter.default.addObserver(
            forName: .featureDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let change = note.object as? LegacyFeatureRepository.FeatureChange else { return }

            switch change {
            case .fileSharingEnabled, .fileSharingDisabled:
                self?.reloadData()

            default:
                break
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationItem()
        flushLayout()

        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        // Prevent content overlaps navi bar
        navigationController?.navigationBar.isTranslucent = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textSearchController.teardown()
    }

    // MARK: - device orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }

    private func flushLayout() {
        for cell in contentView.collectionView.visibleCells {
            guard let cell = cell as? CollectionCell else {
                continue
            }

            cell.flushCachedSize()
        }

        contentView.collectionViewLayout.invalidateLayout()
        contentView.collectionViewLayout.finalizeCollectionViewUpdates()
    }

    private func trackOpeningIfNeeded() {
        guard shouldTrackOnNextOpen, fetchingDone else { return }

        shouldTrackOnNextOpen = false
    }

    @objc
    private func reloadData() {
        UIView.performWithoutAnimation {
            contentView.collectionView.performBatchUpdates({
                for section in [CollectionsSectionSet.images, CollectionsSectionSet.videos]
                    where numberOfElements(for: section) != 0 {
                    contentView.collectionView
                        .reloadSections(IndexSet(integer: (collectionsSectionSet.firstIndex(of: section))!))
                }
            }, completion: { _ in
                self.contentView.collectionView.reloadData()
            })
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if lastLayoutSize != view.bounds.size {
            lastLayoutSize = view.bounds.size

            DispatchQueue.main.async {
                self.flushLayout()
                self.reloadData()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackOpeningIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard view.window != nil else {
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.flushLayout()
        }, completion: { _ in
            self.reloadData()
        })
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    private func updateNoElementsState() {
        contentView.noItemsInLibrary = fetchingDone && inOverviewMode && totalNumberOfElements() == 0
    }

    private func setupNavigationItem() {

        // The label must be inset from the top due to navigation bar title alignment
        let titleViewWrapper = UIView()
        let titleView = ConversationTitleView(conversation: collection.conversation, interactive: false)
        titleViewWrapper.addSubview(titleView)

        [titleView, titleViewWrapper].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: titleViewWrapper.topAnchor, constant: 4),
            titleView.leftAnchor.constraint(equalTo: titleViewWrapper.leftAnchor),
            titleView.rightAnchor.constraint(equalTo: titleViewWrapper.rightAnchor),
            titleView.bottomAnchor.constraint(equalTo: titleViewWrapper.bottomAnchor)
        ])

        titleViewWrapper.setNeedsLayout()

        let size = titleViewWrapper.systemLayoutSizeFitting(CGSize(width: 320, height: 44))
        titleViewWrapper.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        navigationItem.titleView = titleViewWrapper

        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Accessibility.ConversationSearch.CloseButton.description)

        if !inOverviewMode,
           let count = navigationController?.viewControllers.count,
           count > 1 {
            let backButton = CollectionsView.backButton()
            backButton.addTarget(
                self,
                action: #selector(CollectionsViewController.backButtonPressed(_:)),
                for: .touchUpInside
            )
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
    }

    @objc
    private func backButtonPressed(_ button: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}

extension CollectionsViewController: AssetCollectionDelegate {
    func assetCollectionDidFetch(
        collection: ZMCollection,
        messages: [CategoryMatch: [ZMConversationMessage]],
        hasMore: Bool
    ) {

        for messageCategory in messages {
            let conversationMessages = messageCategory.value

            if messageCategory.key.including.contains(.image) {
                imageMessages.append(contentsOf: conversationMessages)
            }

            if messageCategory.key.including.contains(.file) {
                fileAndAudioMessages.append(contentsOf: conversationMessages)
            }

            if messageCategory.key.including.contains(.linkPreview) {
                linkMessages.append(contentsOf: conversationMessages)
            }

            if messageCategory.key.including.contains(.video) {
                videoMessages.append(contentsOf: conversationMessages)
            }
        }

        if isViewLoaded {
            updateNoElementsState()
            contentView.collectionView.reloadData()
        }
    }

    func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
        fetchingDone = true
    }
}

extension CollectionsViewController: UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {

    private func elements(for section: CollectionsSectionSet) -> [ZMConversationMessage] {
        switch section {
        case CollectionsSectionSet.images:
            imageMessages
        case CollectionsSectionSet.filesAndAudio:
            fileAndAudioMessages
        case CollectionsSectionSet.videos:
            videoMessages
        case CollectionsSectionSet.links:
            linkMessages
        default: fatal("Unknown section")
        }
    }

    private func numberOfElements(for section: CollectionsSectionSet) -> Int {
        switch section {
        case CollectionsSectionSet.images:
            let max = inOverviewMode ? maxOverviewElementsInGrid(in: section) : Int.max
            return min(imageMessages.count, max)

        case CollectionsSectionSet.filesAndAudio:
            let max = inOverviewMode ? maxOverviewElementsInTable : Int.max
            return min(fileAndAudioMessages.count, max)

        case CollectionsSectionSet.videos:
            let max = inOverviewMode ? maxOverviewElementsInGrid(in: section) : Int.max
            return min(videoMessages.count, max)

        case CollectionsSectionSet.links:
            let max = inOverviewMode ? maxOverviewElementsInTable : Int.max
            return min(linkMessages.count, max)

        case CollectionsSectionSet.loading, .searchFiles:
            return 1

        default: fatal("Unknown section")
        }
    }

    private func totalNumberOfElements() -> Int {
        // Empty collection contains one element (loading cell)
        collectionsSectionSet.map { numberOfElements(for: $0) }.reduce(0, +) - 1
    }

    private func moreElementsToSee(in section: CollectionsSectionSet) -> Bool {
        elements(for: section).count > numberOfElements(for: section)
    }

    private func message(for indexPath: IndexPath) -> ZMConversationMessage {
        let section = collectionSection(for: indexPath.section)

        return elements(for: section)[indexPath.row]
    }

    private func gridElementSize(in section: CollectionsSectionSet) -> CGSize {
        let sectionHorizontalInset = horizontalInset(in: section)

        let size = (contentView.collectionView.bounds.size.width - sectionHorizontalInset) /
            CGFloat(elementsPerLine(in: section))

        return CGSize(width: size - 1, height: size - 1)
    }

    private func elementsPerLine(in section: CollectionsSectionSet) -> Int {
        var count = 1
        let sectionHorizontalInset = horizontalInset(in: section)

        repeat {
            count += 1
        } while (contentView.collectionView.bounds.size.width - sectionHorizontalInset) / CGFloat(count) >
            CollectionImageCell.maxCellSize

        return count
    }

    private func maxOverviewElementsInGrid(in section: CollectionsSectionSet) -> Int {
        elementsPerLine(in: section) * 2 // 2 lines of elements
    }

    private var maxOverviewElementsInTable: Int {
        3
    }

    private func sizeForCell(at indexPath: IndexPath) -> (CGFloat?, CGFloat?) {
        let section = collectionSection(for: indexPath.section)

        let gridElementSize = gridElementSize(in: section)

        var desiredWidth: CGFloat?
        var desiredHeight: CGFloat?

        switch section {
        case CollectionsSectionSet.images, CollectionsSectionSet.videos:
            desiredWidth = gridElementSize.width
            desiredHeight = gridElementSize.height

        case CollectionsSectionSet.filesAndAudio:
            desiredWidth = contentView.collectionView.bounds.size.width - horizontalInset(in: section)
            if !CollectionsView.useAutolayout {
                desiredHeight = 96
            }

        case CollectionsSectionSet.links:
            desiredWidth = contentView.collectionView.bounds.size.width - horizontalInset(in: section)
            if !CollectionsView.useAutolayout {
                desiredHeight = 98
            }

        case CollectionsSectionSet.loading:
            desiredWidth = contentView.collectionView.bounds.size.width - horizontalInset(in: section)
            if !CollectionsView.useAutolayout {
                desiredHeight = fetchingDone ? 24 : 88
            }

        case CollectionsSectionSet.searchFiles:
            desiredWidth = contentView.collectionView.bounds.size.width - horizontalInset(in: section)
            if !CollectionsView.useAutolayout {
                desiredHeight = 50
            }

        default: fatal("Unknown section")
        }

        return (desiredWidth, desiredHeight)
    }

    private func horizontalInset(in section: CollectionsSectionSet) -> CGFloat {
        let insets = sectionInsets(in: section)
        return insets.left + insets.right
    }

    private func sectionInsets(in section: CollectionsSectionSet) -> UIEdgeInsets {
        if section == CollectionsSectionSet.loading || section == .searchFiles {
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }

        return elements(for: section).isEmpty ? .zero : UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
    }

    // MARK: - Data Source

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionsSectionSet.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = collectionSection(for: section)

        return numberOfElements(for: section)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let (width, height) = sizeForCell(at: indexPath)
        return CGSize(width: width ?? 0, height: height ?? 0)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let section = collectionSection(for: indexPath.section)

        let resultCell: CollectionCell

        switch section {
        case CollectionsSectionSet.images:
            resultCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CollectionImageCell.reuseIdentifier,
                for: indexPath
            ) as! CollectionImageCell

        case CollectionsSectionSet.filesAndAudio:
            if message(for: indexPath).fileMessageData?.isAudio == true {
                let audioCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionAudioCell.reuseIdentifier,
                    for: indexPath
                ) as! CollectionAudioCell
                audioCell.setUserSession(userSession: userSession)
                resultCell = audioCell
            } else {
                resultCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionFileCell.reuseIdentifier,
                    for: indexPath
                ) as! CollectionFileCell
            }

        case CollectionsSectionSet.videos:
            resultCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CollectionVideoCell.reuseIdentifier,
                for: indexPath
            ) as! CollectionVideoCell

        case CollectionsSectionSet.links:
            resultCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CollectionLinkCell.reuseIdentifier,
                for: indexPath
            ) as! CollectionLinkCell

        case CollectionsSectionSet.loading:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CollectionLoadingCell.reuseIdentifier,
                for: indexPath
            ) as! CollectionLoadingCell
            cell.collapsed = fetchingDone
            cell.containerWidth = collectionView.bounds.size.width - horizontalInset(in: section)
            return cell

        case CollectionsSectionSet.searchFiles:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CollectionSearchFilesCell.reuseIdentifier,
                for: indexPath
            ) as! CollectionSearchFilesCell
            let accentColor = WireAccentColor(
                rawValue: userSession.selfUser.accentColorValue
            )
            cell.configure(accentColor: accentColor) { [weak self] in
                self?.showSearchFilesAlert()
            }
            return cell

        default: fatal("Unknown section")
        }

        let message = message(for: indexPath)
        resultCell.message = message
        resultCell.delegate = self
        resultCell.messageChangeDelegate = self

        if CollectionsView.useAutolayout {
            let (width, height) = sizeForCell(at: indexPath)

            resultCell.desiredWidth = width
            resultCell.desiredHeight = height
        }

        return resultCell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let section = collectionSection(for: indexPath.section)

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CollectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as! CollectionHeaderView
            header.section = section
            header.totalItemsCount = UInt(moreElementsToSee(in: section) ? elements(for: section).count : 0)
            header.selectionAction = { [weak self] section in
                guard let self else {
                    return
                }
                let collectionController = CollectionsViewController(
                    collection: collection,
                    sections: section,
                    messages: elements(for: section),
                    isCellsEnabled: isCellsEnabled,
                    fetchingDone: fetchingDone,
                    userSession: userSession,
                    mainCoordinator: mainCoordinator,
                    selfProfileUIBuilder: selfProfileUIBuilder,
                    conversationCreationRepository: conversationCreationRepository
                )
                collectionController.onDismiss = onDismiss
                collectionController.delegate = delegate
                navigationController?.pushViewController(collectionController, animated: true)
            }
            let size = self.collectionView(
                collectionView,
                layout: contentView.collectionView.collectionViewLayout,
                referenceSizeForHeaderInSection: indexPath.section
            )
            header.desiredWidth = size.width
            header.desiredHeight = size.height
            return header
        default:
            fatal("No supplementary view for \(kind)")
        }
    }

    // MARK: - Layout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        let section = collectionSection(for: section)

        if section == CollectionsSectionSet.loading || section == CollectionsSectionSet.searchFiles {
            return .zero
        }
        return elements(for: section).isEmpty ? .zero : CGSize(width: collectionView.bounds.size.width, height: 48)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        sectionInsets(in: collectionSection(for: section))
    }

    private func collectionSection(for section: Int) -> CollectionsSectionSet {
        guard let section = CollectionsSectionSet(
            index: UInt(section),
            isCellsEnabled: isCellsEnabled
        ) else { fatal("Unknown section") }

        return section
    }

    // MARK: - Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = collectionSection(for: indexPath.section)

        if section == .loading {
            return
        }

        if section == .searchFiles {
            delegate?.collectionsViewControllerDidRequestOpenSearchFiles(self)
            return
        }

        let message = message(for: indexPath)
        perform(.present, for: message, source: collectionView.cellForItem(at: indexPath)!)
    }

    private func showSearchFilesAlert() {
        typealias SearchFiles = L10n.Localizable.Collections.Section.SearchFiles
        let alertController = UIAlertController(
            title: SearchFiles.Alert.title,
            message: SearchFiles.Alert.message,
            preferredStyle: .alert
        )

        let searchFilesAction = UIAlertAction(
            title: SearchFiles.description,
            style: .default
        ) { [weak self] _ in
            guard let self else { return }
            delegate?.collectionsViewControllerDidRequestOpenSearchFiles(self)
        }

        let cancelAction = UIAlertAction(
            title: L10n.Localizable.General.close,
            style: .cancel
        ) { _ in }

        [searchFilesAction, cancelAction].forEach(alertController.addAction)
        present(alertController, animated: true)
    }

}

extension CollectionsViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let section = collectionSection(for: indexPath.section)

            guard section != .loading else {
                continue
            }
        }
    }
}

// MARK: - Message Change

extension CollectionsViewController: CollectionCellMessageChangeDelegate {
    func messageDidChange(_ cell: CollectionCell, changeInfo: MessageChangeInfo) {

        // Open the file when it is downloaded
        guard let message = selectedMessage,
              changeInfo.message == message,
              let fileMessageData = message.fileMessageData,
              fileMessageData.downloadState == .downloaded,
              messagePresenter.waitingForFileDownload,
              message.isFile || message.isVideo || message.isAudio else {
            return
        }

        messagePresenter.openFileMessage(message, targetView: cell)
    }
}

// MARK: - Gestures

extension CollectionsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if navigationController?.interactivePopGestureRecognizer == gestureRecognizer {
            if let count = navigationController?.viewControllers.count, count > 1 {
                true
            } else {
                false
            }
        } else {
            true
        }
    }
}

// MARK: - Actions

extension CollectionsViewController: MessageActionResponder {

    func perform(action: MessageAction, for message: ZMConversationMessage, view: UIView) {
        perform(action, for: message, source: view)
    }
}

extension CollectionsViewController: CollectionCellDelegate {

    func collectionCell(_ cell: CollectionCell, performAction action: MessageAction) {
        guard let message = cell.message else {
            fatal("Cell does not have a message: \(cell)")
        }

        perform(action, for: message, source: cell)
    }

    func perform(_ action: MessageAction, for message: ZMConversationMessage, source: UIView) {
        switch action {
        case .copy:
            if let cell = source as? CollectionCell {
                cell.copyDisplayedContent(in: .general)
            } else {
                message.copy(in: .general)
            }

        case .delete:
            deletionDialogPresenter?.presentDeletionAlertController(
                forMessage: message,
                source: source,
                userSession: userSession
            ) { [weak self] deleted, _ in
                guard deleted else { return }
                _ = self?.navigationController?.popViewController(animated: true)
                self?.refetchCollection()
            }

        case .present:
            selectedMessage = message

            if message.isImage, message.canBeShared {
                let imagesController = ConversationImagesViewController(
                    collection: collection,
                    initialMessage: message,
                    userSession: userSession,
                    mainCoordinator: mainCoordinator,
                    selfProfileUIBuilder: selfProfileUIBuilder,
                    conversationCreationRepository: conversationCreationRepository
                )

                let backButton = CollectionsView.backButton()
                backButton.addTarget(
                    self,
                    action: #selector(CollectionsViewController.backButtonPressed(_:)),
                    for: .touchUpInside
                )
                backButton.accessibilityLabel = L10n.Accessibility.ConversationSearch.BackButton.description

                navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
                    self?.presentingViewController?.dismiss(animated: true)
                }, accessibilityLabel: L10n.Accessibility.ConversationSearch.CloseButton.description)

                imagesController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
                imagesController.swipeToDismiss = false
                imagesController.messageActionDelegate = self
                navigationController?.pushViewController(imagesController, animated: true)
            } else {
                messagePresenter.open(
                    message,
                    targetView: view,
                    actionResponder: self,
                    userSession: userSession,
                    mainCoordinator: mainCoordinator,
                    selfProfileUIBuilder: selfProfileUIBuilder,
                    conversationCreationRepository: conversationCreationRepository
                )
            }

        case .save:
            if message.isImage {
                guard let imageMessageData = message.imageMessageData,
                      let imageData = imageMessageData.imageData else { return }

                let saveableImage = SavableImage(data: imageData, isGIF: imageMessageData.isAnimatedGIF)
                saveableImage.saveToLibrary()

            } else if let fileURL = message.fileMessageData?.temporaryURLToDecryptedFile() {
                let activityViewController = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                if let popoverPresentationController = activityViewController.popoverPresentationController {
                    let sourceView = (source as? CollectionCell)?.selectionView ?? view as UIView
                    popoverPresentationController.sourceView = sourceView.superview
                    popoverPresentationController.sourceRect = sourceView.frame
                }
                present(activityViewController, animated: true)
            } else {
                WireLogger.conversation
                    .warn("Saving a message of any type other than image or file is currently not handled.")
            }

        case .download:
            userSession.enqueue {
                message.fileMessageData?.requestFileDownload()
            }

        case .cancel:
            userSession.enqueue {
                message.fileMessageData?.cancelTransfer()
            }

        case .openDetails:
            let detailsViewController = MessageDetailsViewController(
                message: message,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository
            )
            let navigationController = UINavigationController(rootViewController: detailsViewController)
            navigationController.modalPresentationStyle = .formSheet

            present(navigationController, animated: true)

        default:
            delegate?.collectionsViewController(self, performAction: action, onMessage: message)
        }
    }
}
