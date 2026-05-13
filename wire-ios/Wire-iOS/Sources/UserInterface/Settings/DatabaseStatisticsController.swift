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
import WireDesign
import WireSyncEngine

final class DatabaseStatisticsController: UIViewController {

    let stackView = UIStackView()
    let spinner = UIActivityIndicatorView()

    private let userSession: UserSession
    private let viewModel = DatabaseStatisticsViewModel()

    init(userSession: UserSession) {
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorTheme.Backgrounds.background

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 15

        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(spinner)
        spinner.startAnimating()

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func rowWith(title: String, contents: String) -> UIView {

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.textAlignment = .left

        let contentsLabel = UILabel()
        contentsLabel.text = contents
        contentsLabel.textColor = SemanticColors.Label.textDefault
        contentsLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 200), for: .horizontal)
        contentsLabel.textAlignment = .right

        let stackView = UIStackView(arrangedSubviews: [titleLabel, contentsLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 15

        return stackView
    }

    func render(_ displayState: DatabaseStatisticsViewModel.DisplayState) {
        stackView.arrangedSubviews.filter { $0 !== spinner }.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        displayState.rows.forEach {
            let spinnerIndex = stackView.arrangedSubviews.firstIndex(of: spinner) ?? stackView.arrangedSubviews.count
            stackView.insertArrangedSubview(rowWith(title: $0.title, contents: $0.contents), at: spinnerIndex)
        }

        spinner.isHidden = !displayState.isLoading
        if displayState.isLoading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTitle(L10n.Localizable.Self.Settings.DeveloperOptions.DatabaseStatistics.title.capitalized)
        render(viewModel.startLoading())

        guard let session = userSession as? ZMUserSession else {
            render(viewModel.update(with: DatabaseStatisticsError.unavailableSession))
            return
        }

        let syncMoc = session.managedObjectContext.zm_sync!
        syncMoc.performGroupedBlock {
            do {
                let allConversations = ZMConversation.fetchRequest()

                let version = syncMoc.persistentStoreCoordinator?.managedObjectModel.version ?? "unknown"
                let conversationsCount = try syncMoc.count(for: allConversations)

                allConversations.predicate = NSPredicate(
                    format: "conversationType == %d",
                    ZMConversationType.invalid.rawValue
                )
                let invalidConversationsCount = try syncMoc.count(for: allConversations)

                let users = ZMUser.fetchRequest()
                let usersCount = try syncMoc.count(for: users)

                let messages = ZMMessage.fetchRequest()
                let messagesCount = try syncMoc.count(for: messages)

                let assetMessages = ZMAssetClientMessage.fetchRequest()
                let allAssets = try syncMoc.fetch(assetMessages)
                    .compactMap {
                        $0 as? ZMAssetClientMessage
                    }
                    .map {
                        DatabaseStatisticsViewModel.AssetSummary(
                            size: Int64($0.size),
                            isImage: $0.isImage,
                            isFile: $0.isFile,
                            isVideo: $0.isVideo,
                            isAudio: $0.isAudio
                        )
                    }

                let statistics = DatabaseStatisticsViewModel.Statistics(
                    databaseVersion: version,
                    conversationsCount: conversationsCount,
                    invalidConversationsCount: invalidConversationsCount,
                    usersCount: usersCount,
                    messagesCount: messagesCount,
                    assets: allAssets
                )

                DispatchQueue.main.async {
                    self.render(self.viewModel.update(with: statistics))
                }
            } catch {
                DispatchQueue.main.async {
                    self.render(self.viewModel.update(with: error))
                }
            }
        }
    }
}

private enum DatabaseStatisticsError: LocalizedError {
    case unavailableSession

    var errorDescription: String? {
        "Database statistics are unavailable for this session."
    }
}
