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

import SwiftUI
import WireDesign
import WireSyncEngine

// MARK: - OtherUserClientsListViewController

final class OtherUserClientsListViewController: UIViewController,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource {
    private let headerView: ParticipantDeviceHeaderView
    private let collectionView = UICollectionView(forGroupedSections: ())
    private var clients: [UserClientType]

    private var tokens: [Any?] = []
    private var user: UserType

    private let userSession: UserSession
    private let contextProvider: ContextProvider?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    private let mlsGroupId: MLSGroupID?

    init(
        user: UserType,
        userSession: UserSession,
        contextProvider: ContextProvider?,
        mlsGroupId: MLSGroupID?
    ) {
        self.user = user
        self.clients = OtherUserClientsListViewController.clientsSortedByRelevance(for: user)
        self.headerView = ParticipantDeviceHeaderView(userName: user.name ?? "")
        self.userSession = userSession
        self.contextProvider = contextProvider
        self.mlsGroupId = mlsGroupId
        super.init(nibName: nil, bundle: nil)

        tokens.append(userSession.addUserObserver(self, for: user))

        headerView.delegate = self
        title = L10n.Localizable.Profile.Devices.title
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        }
    }

    deinit {
        DeveloperToolsViewModel.context.currentUserClient = nil
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateCertificatesForUserClients()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        (user as? ZMUser)?.fetchUserClients()
    }

    private func setupViews() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.showUnencryptedLabel = (user as? ZMUser)?.clients.count == 0

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        UserClientCell.register(in: collectionView)
        collectionView.register(
            CollectionViewCellAdapter.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CollectionViewCellAdapter.zm_reuseIdentifier
        )

        view.addSubview(collectionView)
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private static func clientsSortedByRelevance(for user: UserType) -> [UserClientType] {
        user.allClients.sortedByRelevance().filter { !$0.isSelfClient() }
    }

    private func updateCertificatesForUserClients() {
        Task {
            if let mlsGroupId {
                clients = await clients.updateCertificates(
                    mlsGroupId: mlsGroupId, userSession: userSession
                )
            }
            refreshView()
        }
    }

    @MainActor
    func refreshView() {
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDelegateFlowLayout & UICollectionViewDataSource

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        headerView.size(fittingWidth: collectionView.bounds.size.width)

        return headerView.bounds.size
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let headerViewCell = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: CollectionViewCellAdapter.zm_reuseIdentifier,
            for: indexPath
        ) as! CollectionViewCellAdapter

        headerViewCell.wrappedView = headerView

        return headerViewCell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        clients.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: UserClientCell.self, for: indexPath)
        let client = clients[indexPath.row]
        cell.viewModel = .init(userClient: client)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let client = clients[indexPath.row] as? UserClient else { return }
        openDetailsOfClient(client)
    }

    private func openDetailsOfClient(_ client: UserClient) {
        guard
            let navigationController,
            let contextProvider
        else {
            assertionFailure("Unable to display details from conversations as navigation instance is nil")
            return
        }

        let viewModel = makeDeviceInfoViewModel(
            client: client,
            contextProvider: contextProvider
        )
        let detailsViewController = DeviceInfoViewController(rootView: OtherUserDeviceDetailsView(viewModel: viewModel))
        navigationController.pushViewController(detailsViewController, animated: true)
    }

    private func makeDeviceInfoViewModel(
        client: UserClient,
        contextProvider: ContextProvider
    ) -> DeviceInfoViewModel {
        let title = client.isLegalHoldDevice
            ? L10n.Localizable.Device.Class.legalhold
            : (client.deviceClass?.localizedDescription.capitalized ?? client.type.localizedDescription.capitalized)
        let saveFileManager = SaveFileManager(systemFileSavePresenter: SystemSavePresenter())
        let deviceActionsHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: userSession,
            credentials: .none,
            saveFileManager: saveFileManager,
            getProteusFingerprint: userSession.getUserClientFingerprint,
            contextProvider: contextProvider,
            e2eiCertificateEnrollment: userSession.enrollE2EICertificate
        )
        DeveloperToolsViewModel.context.currentUserClient = client

        return DeviceInfoViewModel(
            title: title,
            addedDate: "",
            proteusID: client.proteusSessionID?.clientID.uppercased().splitStringIntoLines(charactersPerLine: 16) ?? "",
            userClient: client,
            isSelfClient: client.isSelfClient(),
            gracePeriod: TimeInterval(userSession.e2eiFeature.config.verificationExpiration),
            mlsCiphersuite: MLSCipherSuite(rawValue: userSession.mlsFeature.config.defaultCipherSuite.rawValue),
            isFromConversation: true,
            actionsHandler: deviceActionsHandler,
            conversationClientDetailsActions: deviceActionsHandler
        )
    }
}

// MARK: UserObserving

extension OtherUserClientsListViewController: UserObserving {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.clientsChanged || changeInfo.trustLevelChanged else { return }

        // swiftlint:disable:next todo_requires_jira_link
        // TODO: add clients to userType
        headerView.showUnencryptedLabel = (user as? ZMUser)?.clients.isEmpty == true
        clients = OtherUserClientsListViewController.clientsSortedByRelevance(for: user)
        updateCertificatesForUserClients()
    }
}

// MARK: ParticipantDeviceHeaderViewDelegate

extension OtherUserClientsListViewController: ParticipantDeviceHeaderViewDelegate {
    func participantsDeviceHeaderViewDidTapLearnMore(_: ParticipantDeviceHeaderView) {
        WireURLs.shared.whyToVerifyFingerprintArticle.openInApp(above: self)
    }
}

extension Array where Element: UserClientType {
    @MainActor
    func updateCertificates(mlsGroupId: MLSGroupID, userSession: UserSession) async -> [UserClientType] {
        guard let userClients = self as? [UserClient] else {
            return self
        }
        var updatedUserClients = [UserClientType]()
        let mlsClients: [Int: MLSClientID] = Dictionary(uniqueKeysWithValues: userClients.compactMap {
            if let mlsClientId = MLSClientID(userClient: $0) {
                ($0.clientId.hashValue, mlsClientId)
            } else {
                nil
            }
        })
        let mlsClienIds = mlsClients.values.map { $0 }
        do {
            let certificates = try await userSession.getE2eIdentityCertificates.invoke(
                mlsGroupId: mlsGroupId,
                clientIds: mlsClienIds
            )
            if !certificates.isEmpty {
                for client in userClients {
                    let mlsClientIdRawValue = mlsClients[client.clientId.hashValue]?.rawValue
                    client.e2eIdentityCertificate = certificates.first(where: { $0.clientId == mlsClientIdRawValue })
                    client.mlsThumbPrint = client.e2eIdentityCertificate?.mlsThumbprint
                    updatedUserClients.append(client)
                }
                return updatedUserClients
            } else {
                return self
            }
        } catch {
            WireLogger.e2ei.error(error.localizedDescription)
            return self
        }
    }
}
