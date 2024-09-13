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

import FLAnimatedImage
import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign
import WireFoundation
import WireSyncEngine
import Ziphy

protocol GiphySearchViewControllerDelegate: AnyObject {
    func giphySearchViewController(
        _ giphySearchViewController: GiphySearchViewController,
        didSelectImageData imageData: Data,
        searchTerm: String
    )
}

final class GiphySearchViewController: VerticalColumnCollectionViewController {
    typealias Giphy = L10n.Localizable.Giphy

    weak var delegate: GiphySearchViewControllerDelegate?

    private let searchResultsController: ZiphySearchResultsController

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = Giphy.searchPlaceholder
        controller.searchBar.isAccessibilityElement = true
        controller.searchBar.accessibilityLabel = L10n.Accessibility.SearchGifs.SearchBar.accessibilityLabel
        controller.searchBar.accessibilityIdentifier = "search input"
        return controller
    }()

    private let noResultsLabel = DynamicFontLabel(
        text: Giphy.Error.noResult,
        style: .body1,
        color: SemanticColors.Label.textSettingsPasswordPlaceholder
    )

    private let conversation: ZMConversation

    private var ziphs: [Ziph] = [] {
        didSet {
            collectionView?.reloadData()
            noResultsLabel.isHidden = ziphs.count > 0
        }
    }

    private var searchTerm: String
    private var pendingTimer: Timer?
    private var pendingSearchtask: CancelableTask?
    private var pendingFetchTask: CancelableTask?

    // MARK: - Initialization

    convenience init(
        searchTerm: String,
        conversation: ZMConversation,
        userSession: UserSession
    ) {
        let searchResultsController = ZiphySearchResultsController(
            client: ZiphyClient(
                host: "api.giphy.com",
                requester: ZiphySession(userSession: userSession),
                downloadSession: URLSession.shared
            ),
            pageSize: 50,
            maxImageSize: 3
        )
        self.init(
            searchTerm: searchTerm,
            conversation: conversation,
            searchResultsController: searchResultsController
        )
    }

    init(
        searchTerm: String,
        conversation: ZMConversation,
        searchResultsController: ZiphySearchResultsController
    ) {
        self.conversation = conversation
        self.searchTerm = searchTerm
        self.searchResultsController = searchResultsController

        let columnCount = AdaptiveColumnCount(
            compact: 2,
            regular: 3,
            large: 4
        )

        super.init(
            interItemSpacing: 1,
            interColumnSpacing: 1,
            columnCount: columnCount
        )

        performSearch()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cleanUpPendingTask()
        cleanUpPendingTimer()
    }

    private func cleanUpPendingTask() {
        pendingSearchtask?.cancel()
        pendingSearchtask = nil
    }

    private func cleanUpPendingTimer() {
        pendingTimer?.invalidate()
        pendingTimer = nil
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        setupNoResultLabel()
        setupCollectionView()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTitle(conversation.displayNameWithFallback)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Localizable.General.close)
        searchController.searchBar.text = searchTerm
    }

    // MARK: - Setup UI

    private func setupSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
    }

    private func setupNoResultLabel() {
        extendedLayoutIncludesOpaqueBars = true
        noResultsLabel.isHidden = true
        noResultsLabel.isAccessibilityElement = true
        noResultsLabel.accessibilityTraits = .staticText
        noResultsLabel.accessibilityLabel = L10n.Accessibility.SearchGifs.NorResultsLabel.description
        view.addSubview(noResultsLabel)
    }

    private func setupCollectionView() {
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.backgroundColor = SemanticColors.View.backgroundDefault
        collectionView?.accessibilityIdentifier = "giphyCollectionView"
        collectionView?.register(
            GiphyCollectionViewCell.self,
            forCellWithReuseIdentifier: GiphyCollectionViewCell.CellIdentifier
        )
        edgesForExtendedLayout = []
    }

    private func createConstraints() {
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Collection View

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        ziphs.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GiphyCollectionViewCell.CellIdentifier,
            for: indexPath
        ) as! GiphyCollectionViewCell
        let ziph = ziphs[indexPath.item]

        guard let representation = ziph.images[.preview] else {
            return cell
        }

        cell.ziph = ziph
        cell.representation = representation
        cell.backgroundColor = AccentColor.random.uiColor
        cell.isAccessibilityElement = true
        cell.accessibilityTraits.insert(.image)
        cell.accessibilityLabel = ziph.title
        cell.accessibilityHint = L10n.Accessibility.SearchGifs.GifItem.accessibilityHint

        searchResultsController.fetchImageData(for: ziph, imageType: .preview) { result in
            guard case let .success(imageData) = result else {
                return
            }

            guard cell.ziph?.identifier == ziph.identifier else {
                return
            }

            cell.imageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, sizeOfItemAt indexPath: IndexPath) -> CGSize {
        let ziph = ziphs[indexPath.item]

        guard let representation = ziph.previewImage else {
            return .zero
        }

        return CGSize(width: representation.width.rawValue, height: representation.height.rawValue)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ziph = ziphs[indexPath.item]
        var previewImage: FLAnimatedImage?

        if let cell = collectionView.cellForItem(at: indexPath) as? GiphyCollectionViewCell {
            previewImage = cell.imageView.animatedImage
        }

        pushConfirmationViewController(ziph: ziph, previewImage: previewImage)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height / 2 {
            fetchMoreResults()
        }

        searchController.searchBar.resignFirstResponder()
    }
}

// MARK: - Search

extension GiphySearchViewController {
    private func performSearch() {
        cleanUpPendingTimer()

        let callback: ZiphyListRequestCallback = { [weak self] result in
            if case let .success(ziphs) = result {
                self?.ziphs = ziphs
            } else {
                self?.ziphs = []
            }
        }

        if searchTerm.isEmpty {
            pendingSearchtask = searchResultsController.trending(callback)
        } else {
            pendingSearchtask = searchResultsController.search(withTerm: searchTerm, callback)
        }
    }

    func performSearchAfter(delay: TimeInterval) {
        cleanUpPendingTask()
        cleanUpPendingTimer()

        pendingTimer = .scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.performSearch()
        }
    }
}

// MARK: - Pagination

extension GiphySearchViewController {
    private func fetchMoreResults() {
        if pendingFetchTask != nil {
            return
        }

        pendingFetchTask = searchResultsController.fetchMoreResults { [weak self] result in
            if case let .success(ziphs) = result {
                self?.collectionView.performBatchUpdates {
                    self?.insertSearchResults(ziphs)
                }
            }

            self?.pendingFetchTask = nil
        }
    }

    private func insertSearchResults(_ results: [Ziph]) {
        ziphs.append(contentsOf: results)

        let updatedIndices = ziphs.indices.suffix(results.count).map {
            IndexPath(item: $0, section: 0)
        }

        collectionView?.insertItems(at: updatedIndices)

        let newItemsCount = results.count
        let announcement = L10n.Accessibility.SearchGifs.GifItemsLoaded.announcement(newItemsCount)
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    @discardableResult
    func pushConfirmationViewController(
        ziph: Ziph?,
        previewImage: FLAnimatedImage?,
        animated: Bool = true
    ) -> GiphyConfirmationViewController {
        let confirmationController = GiphyConfirmationViewController(
            withZiph: ziph,
            previewImage: previewImage,
            searchResultController: searchResultsController
        )
        confirmationController.title = conversation.displayNameWithFallback
        confirmationController.delegate = self
        navigationController?.pushViewController(confirmationController, animated: animated)

        return confirmationController
    }
}

// MARK: - GiphyConfirmationViewControllerDelegate

extension GiphySearchViewController: GiphyConfirmationViewControllerDelegate {
    func giphyConfirmationViewController(
        _ giphyConfirmationViewController: GiphyConfirmationViewController,
        didConfirmImageData imageData: Data
    ) {
        delegate?.giphySearchViewController(self, didSelectImageData: imageData, searchTerm: searchTerm)
    }
}

extension GiphySearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        searchTerm = searchText
        performSearchAfter(delay: 0.3)
    }
}

extension GiphySearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_: UISearchBar) {
        performSearch()
    }
}
