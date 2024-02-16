//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSyncEngine
import WireCommonComponents
import SwiftUI

private let zmLog = ZMSLog(tag: "UI")

final class ClientListViewController: UIViewController,
                                UITableViewDelegate,
                                UITableViewDataSource,
                                ClientUpdateObserver,
                                ClientColorVariantProtocol,
                                SpinnerCapable {
    // MARK: SpinnerCapable
    var dismissSpinner: SpinnerCompletion?

    var removalObserver: ClientRemovalObserver?

    var clientsTableView: UITableView?
    let topSeparator = OverflowSeparatorView()
    weak var delegate: ClientListViewControllerDelegate?

    var editingList: Bool = false {
        didSet {
            guard !clients.isEmpty else {
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.setHidesBackButton(false, animated: true)
                return
            }

            createRightBarButtonItem()

            self.navigationItem.setHidesBackButton(self.editingList, animated: true)

            self.clientsTableView?.setEditing(self.editingList, animated: true)
        }
    }

    var clients: [UserClient] = [] {
        didSet {
            self.sortedClients = self.clients.filter(clientFilter).sorted(by: clientSorter)
            self.clientsTableView?.reloadData()

            if !clients.isEmpty {
                createRightBarButtonItem()
            } else {
                self.editingList = false
            }
        }
    }

    private let clientSorter: (UserClient, UserClient) -> Bool
    private let clientFilter: (UserClient) -> Bool
    private let userSession: UserSession?
    private let contextProvider: ContextProvider?
    var sortedClients: [UserClient] = []

    var selfClient: UserClient?
    let detailedView: Bool
    var credentials: ZMEmailCredentials?
    var clientsObserverToken: Any?
    var userObserverToken: NSObjectProtocol?

    var leftBarButtonItem: UIBarButtonItem? {
        if self.isIPadRegular() {
            return UIBarButtonItem.createNavigationRightBarButtonItem(
                systemImage: true,
                target: self,
                action: #selector(ClientListViewController.backPressed(_:)))
        }

        if let rootViewController = self.navigationController?.viewControllers.first,
            self.isEqual(rootViewController) {
            return UIBarButtonItem.createNavigationRightBarButtonItem(
                systemImage: true,
                target: self,
                action: #selector(ClientListViewController.backPressed(_:)))
        }

        return nil
    }

    required init(
        clientsList: [UserClient]?,
        selfClient: UserClient? = ZMUserSession.shared()?.selfUserClient,
        userSession: UserSession? = ZMUserSession.shared(),
        credentials: ZMEmailCredentials? = .none,
        contextProvider: ContextProvider? = ZMUserSession.shared(),
        detailedView: Bool = false,
        showTemporary: Bool = true,
        showLegalHold: Bool = true
    ) {
        self.userSession = userSession
        self.selfClient = selfClient
        self.detailedView = detailedView
        self.credentials = credentials
        self.contextProvider = contextProvider

        clientFilter = {
            $0 != selfClient && (showTemporary || $0.type != .temporary) && (showLegalHold || $0.type != .legalHold)
        }

        clientSorter = {
            guard let leftDate = $0.activationDate, let rightDate = $1.activationDate else { return false }
            return leftDate.compare(rightDate) == .orderedDescending
        }

        super.init(nibName: nil, bundle: nil)
        setupControllerTitle()

        self.initalizeProperties(clientsList ?? Array(ZMUser.selfUser()?.clients.filter { !$0.isSelfClient() } ?? []))
        self.clientsObserverToken = ZMUserSession.shared()?.addClientUpdateObserver(self)
        if let user = ZMUser.selfUser(), let session = ZMUserSession.shared() {
            self.userObserverToken = UserChangeInfo.add(observer: self, for: user, in: session)
        }

        if clientsList == nil {
            if clients.isEmpty {
                (navigationController as? SpinnerCapableViewController ?? self).isLoadingViewVisible = true
            }
            userSession?.fetchAllClients()
        }
    }

    @available(*, unavailable)
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initalizeProperties(_ clientsList: [UserClient]) {
        self.clients = clientsList.filter { !$0.isSelfClient() }
        self.editingList = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.createTableView()
        self.view.addSubview(self.topSeparator)
        self.createConstraints()

        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        self.navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.ClientsList.BackButton.description
        setColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.clientsTableView?.reloadData()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissLoadingView()

        // Prevent more then one removalObserver in self and SettingsClientViewController
        removalObserver = nil
    }

    private func dismissLoadingView() {
        (navigationController as? SpinnerCapableViewController)?.isLoadingViewVisible = false
        isLoadingViewVisible = false
    }

    func openDetailsOfClient(_ client: UserClient) {
        guard let userSession = userSession,
              let navigationController = self.navigationController
        else {
            assertionFailure("Unable to display Devices screen.UserSession and/or navigation instances are nil")
            return
        }
        let viewModel = DeviceInfoViewModel.map(
            certificate: client.e2eIdentityCertificate,
            userClient: client,
            title: client.isLegalHoldDevice ? L10n.Localizable.Device.Class.legalhold : (client.model ?? ""),
            addedDate: client.activationDate?.formattedDate ?? "",
            proteusID: client.proteusSessionID?.clientID.uppercased().splitStringIntoLines(charactersPerLine: 16),
            isSelfClient: client.isSelfClient(),
            userSession: userSession,
            credentials: credentials,
            gracePeriod: TimeInterval(userSession.e2eiFeature.config.verificationExpiration),
            mlsThumbprint: (client.e2eIdentityCertificate?.mlsThumbprint ?? client.mlsPublicKeys.ed25519)?.splitStringIntoLines(charactersPerLine: 16),
            getProteusFingerprint: userSession.getUserClientFingerprint
        )
        let detailsView = DeviceDetailsView(viewModel: viewModel) {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
        let hostingViewController = UIHostingController(rootView: detailsView)
        hostingViewController.view.backgroundColor = SemanticColors.View.backgroundDefault
        navigationController.pushViewController(hostingViewController, animated: true)
        navigationController.isNavigationBarHidden = true
    }

    @MainActor
    private func fetchSelfConversation() async -> MLSGroupID? {
        guard let syncContext = contextProvider?.syncContext else {
            return nil
        }
        return await syncContext.perform {
            return ZMConversation.fetchSelfMLSConversation(in: syncContext)?.mlsGroupID
        }
    }

    private func createTableView() {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.register(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.isEditing = self.editingList
        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        self.clientsTableView = tableView
    }

    private func createConstraints() {
        guard let clientsTableView = clientsTableView else {
            return
        }

        clientsTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            clientsTableView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            clientsTableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            clientsTableView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            clientsTableView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])
    }

    private func convertSection(_ section: Int) -> Int {
        if self.selfClient != nil {
            return section
        } else {
            return section + 1
        }
    }

    // MARK: - Actions

    @objc func startEditing(_ sender: AnyObject!) {
        self.editingList = true
    }

    @objc private func endEditing(_ sender: AnyObject!) {
        self.editingList = false
    }

    @objc func backPressed(_ sender: AnyObject!) {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func deleteUserClient(_ userClient: UserClient,
                          credentials: ZMEmailCredentials?) {
        removalObserver = nil

        removalObserver = ClientRemovalObserver(userClientToDelete: userClient,
                                                delegate: self,
                                                credentials: credentials)

        removalObserver?.startRemoval()

        delegate?.finishedDeleting(self)
    }

    // MARK: - ClientRegistrationObserver

    func finishedFetching(_ userClients: [UserClient]) {
        Task {
            let updatedClients = await updateCertificates(for: userClients)
            await MainActor.run {
                dismissLoadingView()
                clients = updatedClients.filter { !$0.isSelfClient() }
            }
        }
    }

    func failedToFetchClients(_ error: Error) {
        dismissLoadingView()

        zmLog.error("Clients request failed: \(error.localizedDescription)")

        presentAlertWithOKButton(message: L10n.Localizable.Error.User.unkownError)
    }

    func finishedDeleting(_ remainingClients: [UserClient]) {
        clients = remainingClients

        editingList = false
    }

    func failedToDeleteClients(_ error: Error) {
        // no-op
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        if self.selfClient != nil, self.sortedClients.count > 0 {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.convertSection(section) {
        case 0:
            if self.selfClient != nil {
                return 1
            } else {
                return 0
            }
        case 1:
            return self.sortedClients.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.convertSection(section) {
        case 0:
            if self.selfClient != nil {
                return L10n.Localizable.Registration.Devices.currentListHeader
            } else {
                return nil
            }
        case 1:
            return L10n.Localizable.Registration.Devices.activeListHeader
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch self.convertSection(section) {
        case 0:
            return nil
        case 1:
            return L10n.Localizable.Registration.Devices.activeListSubtitle
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = headerFooterViewTextColor
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = headerFooterViewTextColor
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ClientTableViewCell.zm_reuseIdentifier, for: indexPath) as? ClientTableViewCell {
            cell.selectionStyle = .none
            cell.showDisclosureIndicator()

            switch self.convertSection((indexPath as NSIndexPath).section) {
            case 0:
                if let selfClient = selfClient {
                    cell.viewModel = ClientTableViewCellModel.from(userClient: selfClient, shouldSetType: false)
                    cell.wr_editable = false
                }
            case 1:
                cell.viewModel = ClientTableViewCellModel.from(userClient: sortedClients[indexPath.row], shouldSetType: false)
                cell.wr_editable = true
            default:
                cell.viewModel = nil
            }

            cell.accessibilityTraits = .button
            cell.accessibilityHint = L10n.Accessibility.ClientsList.DeviceDetails.hint

            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch self.convertSection((indexPath as NSIndexPath).section) {
        case 1:

            let userClient = self.sortedClients[indexPath.row]

            self.deleteUserClient(userClient, credentials: credentials)
        default: break
        }

    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch self.convertSection((indexPath as NSIndexPath).section) {
        case 0:
            return .none
        case 1:
            return sortedClients[indexPath.row].type == .legalHold ? .none : .delete
        default:
            return .none
        }

    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.detailedView {
            return
        }

        switch self.convertSection((indexPath as NSIndexPath).section) {
        case 0:
            if let selfClient = self.selfClient {
                self.openDetailsOfClient(selfClient)
            }

        case 1:
            self.openDetailsOfClient(self.sortedClients[indexPath.row])

        default:
            break
        }

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topSeparator.scrollViewDidScroll(scrollView: scrollView)
    }

    func createRightBarButtonItem() {
        if self.editingList {
            let doneButtonItem: UIBarButtonItem = .createNavigationRightBarButtonItem(title: L10n.Localizable.General.done.capitalized,
                                                                                      systemImage: false,
                                                                                      target: self,
                                                                                      action: #selector(ClientListViewController.endEditing(_:)))
            self.navigationItem.rightBarButtonItem = doneButtonItem

            self.navigationItem.setLeftBarButton(nil, animated: true)
        } else {
            let editButtonItem: UIBarButtonItem = .createNavigationRightBarButtonItem(title: L10n.Localizable.General.edit.capitalized,
                                                                                      systemImage: false,
                                                                                      target: self,
                                                                                      action: #selector(ClientListViewController.startEditing(_:)))
            self.navigationItem.rightBarButtonItem = editButtonItem
            self.navigationItem.setLeftBarButton(leftBarButtonItem, animated: true)
        }
    }

    private func setupControllerTitle() {
        navigationItem.setupNavigationBarTitle(title: L10n.Localizable.Registration.Devices.title.capitalized)
    }

    @MainActor
    private func updateCertificates(for userClients: [UserClient]) async -> [UserClient] {
        let mlsGroupID = await fetchSelfConversation()
        if let mlsGroupID = mlsGroupID, let userSession = userSession {
            var updatedUserClients = [UserClient]()
            let mlsResolver = MLSClientResolver()
            let mlsClients: [Int: MLSClientID] = Dictionary(uniqueKeysWithValues: userClients.compactMap {
                if let mlsClientId = mlsResolver.mlsClientId(for: $0) {
                    ($0.clientId.hashValue, mlsClientId)
                } else {
                    nil
                }
            })
            let mlsClienIds = Array(mlsClients.values)
            do {
                let isE2eIEnabledForSelfClient = try await userSession.getIsE2eIdentityEnabled.invoke()
                let certificates = try await userSession.getE2eIdentityCertificates.invoke(mlsGroupId: mlsGroupID,
                                                                                           clientIds: mlsClienIds)
                if certificates.isNonEmpty {
                    for client in userClients {
                        let mlsClientIdRawValue = mlsClients[client.clientId.hashValue]?.rawValue
                        client.e2eIdentityCertificate = certificates.first { $0.clientId == mlsClientIdRawValue }
                        client.mlsThumbPrint = client.e2eIdentityCertificate?.mlsThumbprint ?? client.mlsPublicKeys.ed25519
                        if client.e2eIdentityCertificate == nil && client.mlsPublicKeys.ed25519 != nil {
                            client.e2eIdentityCertificate = client.notActivatedE2EIdenityCertificate()
                        }
                        updatedUserClients.append(client)
                    }
                    if let selfClient = selfClient {
                        selfClient.e2eIdentityCertificate = certificates.first(where: {
                            $0.clientId == mlsResolver.mlsClientId(for: selfClient)?.rawValue
                        })
                        if certificates.isNonEmpty {
                            selfClient.e2eIdentityCertificate = selfClient.notActivatedE2EIdenityCertificate()
                        }
                        selfClient.mlsThumbPrint = selfClient.e2eIdentityCertificate?.mlsThumbprint ?? selfClient.mlsPublicKeys.ed25519
                    }
                    return updatedUserClients
                } else if isE2eIEnabledForSelfClient {
                    for client in clients {
                        if let mlsThumbprint = client.mlsPublicKeys.ed25519,
                           !mlsThumbprint.isEmpty {
                            client.e2eIdentityCertificate = client.notActivatedE2EIdenityCertificate()
                            updatedUserClients.append(client)
                        }
                    }
                    return updatedUserClients
                } else {
                    return userClients
                }
            } catch {
                WireLogger.e2ei.error(error.localizedDescription)
                return userClients
            }
        } else {
            return userClients
        }
    }
}

// MARK: - ClientRemovalObserverDelegate

extension ClientListViewController: ClientRemovalObserverDelegate {
    func setIsLoadingViewVisible(_ clientRemovalObserver: ClientRemovalObserver, isVisible: Bool) {
        guard removalObserver == clientRemovalObserver else {
            return
        }

        isLoadingViewVisible = isVisible
    }

    func present(_ clientRemovalObserver: ClientRemovalObserver, viewControllerToPresent: UIViewController) {
        guard removalObserver == clientRemovalObserver else {
            return
        }

        present(viewControllerToPresent, animated: true)
    }
}

extension ClientListViewController: UserObserving {

    func userDidChange(_ note: UserChangeInfo) {
        if note.clientsChanged || note.trustLevelChanged {
            guard let selfUser = ZMUser.selfUser(), let selfClient = selfUser.selfClient() else {
                return
            }

            var clients = selfUser.clients
            clients.remove(selfClient)
            self.clients = Array(clients)
            Task {
                self.clients = await updateCertificates(for: self.clients)
                refreshViews()
            }
        }
    }

    @MainActor
    func refreshViews() {
        clientsTableView?.reloadData()
    }
}

private extension UserClient {
    func notActivatedE2EIdenityCertificate() -> E2eIdentityCertificate? {
        guard let mlsResolver = MLSClientResolver().mlsClientId(for: self) else {
            return nil
        }
        return E2eIdentityCertificate(
            clientId: mlsResolver.rawValue,
            certificateDetails: "",
            mlsThumbprint: self.mlsPublicKeys.ed25519 ?? "",
            notValidBefore: .now,
            expiryDate: .now,
            certificateStatus: .notActivated,
            serialNumber: ""
        )
    }
}
