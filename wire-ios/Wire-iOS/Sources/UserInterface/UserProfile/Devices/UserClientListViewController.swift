//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireSyncEngine
import SwiftUI

final class UserClientListViewController: UIViewController,
                                          UICollectionViewDelegateFlowLayout,
                                          UICollectionViewDataSource {

    private let headerView: ParticipantDeviceHeaderView
    private let collectionView = UICollectionView(forGroupedSections: ())
    private var clients: [UserClientType] {
        didSet {
            self.clientInstances = clients.compactMap({ $0 as? UserClient })
        }
    }
    private var clientInstances = [UserClient]()

    private var tokens: [Any?] = []
    private var user: UserType

    private let userSession: UserSession
    private let contextProvider: ContextProvider?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    private let mlsGroupId: MLSGroupID?

    init(user: UserType,
         userSession: UserSession,
         contextProvider: ContextProvider?,
         mlsGroupId: MLSGroupID?) {
        self.user = user
        self.clients = UserClientListViewController.clientsSortedByRelevance(for: user)
        self.headerView = ParticipantDeviceHeaderView(userName: user.name ?? "")
        self.userSession = userSession
        self.contextProvider = contextProvider
        self.mlsGroupId = mlsGroupId
        super.init(nibName: nil, bundle: nil)

        tokens.append(userSession.addUserObserver(self, for: user))

        self.headerView.delegate = self
        self.clientInstances = clients.compactMap({ $0 as? UserClient })
        title = L10n.Localizable.Profile.Devices.title
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        }
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
        collectionView.register(CollectionViewCellAdapter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionViewCellAdapter.zm_reuseIdentifier)

        view.addSubview(collectionView)
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private static func clientsSortedByRelevance(for user: UserType) -> [UserClientType] {
        return user.allClients.sortedByRelevance().filter({ !$0.isSelfClient() })
    }

    private func updateCertificatesForUserClients() {
        Task {
            if let mlsGroupId = mlsGroupId {
                clients = await clientInstances.updateCertificates(
                    mlsGroupId: mlsGroupId, userSession: userSession)
            }
            await MainActor.run {
                collectionView.reloadData()
            }
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout & UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        headerView.size(fittingWidth: collectionView.bounds.size.width)

        return headerView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerViewCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewCellAdapter.zm_reuseIdentifier, for: indexPath) as! CollectionViewCellAdapter

        headerViewCell.wrappedView = headerView

        return headerViewCell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return clients.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: UserClientCell.self, for: indexPath)
        let client = clientInstances[indexPath.row]
        cell.viewModel = .from(userClient: client)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let client = clientInstances[indexPath.row]
        let profileClientViewController = ProfileClientViewController(
            client: client,
            fromConversation: true,
            userSession: userSession
        )
        profileClientViewController.showBackButton = false

        show(profileClientViewController, sender: nil)
    }
}

extension UserClientListViewController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.clientsChanged || changeInfo.trustLevelChanged else { return }

        // swiftlint:disable todo_requires_jira_link
        // TODO: add clients to userType
        // swiftlint:enable todo_requires_jira_link
        headerView.showUnencryptedLabel = (user as? ZMUser)?.clients.isEmpty == true
        clients = UserClientListViewController.clientsSortedByRelevance(for: user)
        updateCertificatesForUserClients()
    }

}

extension UserClientListViewController: ParticipantDeviceHeaderViewDelegate {
    func participantsDeviceHeaderViewDidTapLearnMore(_ headerView: ParticipantDeviceHeaderView) {
        URL.wr_fingerprintLearnMore.openInApp(above: self)
    }
}

extension Array where Element: UserClient {

    @MainActor
    func updateCertificates(mlsGroupId: MLSGroupID, userSession: UserSession) async -> [UserClient] {
        var updatedUserClients = [UserClient]()
        let mlsResolver = MLSClientResolver()
        let mlsClients: [Int: MLSClientID] = Dictionary(uniqueKeysWithValues: self.compactMap {
            if let mlsClientId = mlsResolver.mlsClientId(for: $0) {
                ($0.clientId.hashValue, mlsClientId)
            } else {
                nil
            }
        })
        let mlsClienIds = mlsClients.values.map({ $0 })
        do {
            let certificates = try await userSession.getE2eIdentityCertificates.invoke(mlsGroupId: mlsGroupId,
                                                                                       clientIds: mlsClienIds)
            if certificates.isNonEmpty {
                for client in self {
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
