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
import WireCommonComponents
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

private let zmLog = ZMSLog(tag: "UI")

// MARK: - ClientListViewController

final class ClientListViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    ClientUpdateObserver,
    ClientColorVariantProtocol {
    // MARK: Lifecycle

    required init(
        clientsList: [UserClient]?,
        selfClient: UserClient? = ZMUserSession.shared()?.selfUserClient,
        userSession: UserSession? = ZMUserSession.shared(),
        credentials: UserEmailCredentials? = .none,
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

        self.clientFilter = {
            $0 != selfClient && (showTemporary || $0.type != .temporary) && (showLegalHold || $0.type != .legalHold)
        }

        self.clientSorter = {
            guard let leftDate = $0.activationDate, let rightDate = $1.activationDate else {
                return false
            }
            return leftDate.compare(rightDate) == .orderedDescending
        }

        super.init(nibName: nil, bundle: nil)

        initalizeProperties(clientsList ?? Array(ZMUser.selfUser()?.clients.filter { !$0.isSelfClient() } ?? []))
        self.clientsObserverToken = ZMUserSession.shared()?.addClientUpdateObserver(self)
        if let user = ZMUser.selfUser(), let session = userSession as? ZMUserSession {
            self.userObserverToken = UserChangeInfo.add(observer: self, for: user, in: session)
        }

        if clientsList == nil {
            if clients.isEmpty {
                activityIndicator.start()
            }
            userSession?.fetchAllClients()
        }
    }

    @available(*, unavailable)
    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: SpinnerCapable

    var removalObserver: ClientRemovalObserver?

    private(set) lazy var activityIndicator = BlockingActivityIndicator(view: navigationController?.view ?? view)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createTableView()
        view.addSubview(topSeparator)
        createConstraints()

        navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.ClientsList.BackButton
            .description
        setColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clientsTableView?.reloadData()
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupNavigationBarTitle(L10n.Localizable.Registration.Devices.title)
        updateAllClients()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissLoadingView()

        // Prevent more then one removalObserver in self and SettingsClientViewController
        removalObserver = nil
    }

    func openDetailsOfClient(_ client: UserClient) {
        guard let userSession,
              let contextProvider,
              let navigationController
        else {
            assertionFailure("Unable to display Devices screen.UserSession and/or navigation instances are nil")
            return
        }

        let viewModel = makeDeviceInfoViewModel(
            client: client,
            userSession: userSession,
            contextProvider: contextProvider
        )
        viewModel.showCertificateUpdateSuccess = { [weak self] certificateChain in
            guard let self else {
                return
            }
            updateAllClients {
                self.updateE2EIdentityCertificateInDetailsView()
            }

            let successEnrollmentViewController = SuccessfulCertificateEnrollmentViewController(isUpdateMode: true)
            successEnrollmentViewController.certificateDetails = certificateChain
            successEnrollmentViewController.onOkTapped = { viewController in
                viewController.dismiss(animated: true)
            }
            successEnrollmentViewController.presentTopmost()
        }
        selectedDeviceInfoViewModel = viewModel

        let detailsViewController = DeviceInfoViewController(rootView: DeviceDetailsView(viewModel: viewModel))
        navigationController.pushViewController(detailsViewController, animated: true)
    }

    @objc
    func backPressed(_: AnyObject!) {
        navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func deleteUserClient(
        _ userClient: UserClient,
        credentials: UserEmailCredentials?
    ) {
        removalObserver = ClientRemovalObserver(
            userClientToDelete: userClient,
            delegate: self,
            credentials: credentials
        )
        removalObserver?.startRemoval()

        delegate?.finishedDeleting(self)
    }

    // MARK: - ClientRegistrationObserver

    func finishedFetching(_ userClients: [UserClient]) {
        Task {
            await updateCertificates(for: userClients)
            await MainActor.run {
                dismissLoadingView()
            }
        }
    }

    func failedToFetchClients(_ error: Error) {
        dismissLoadingView()

        zmLog.error("Clients request failed: \(error.localizedDescription)")

        let alert = UIAlertController(
            title: title,
            message: L10n.Localizable.Error.User.unkownError,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        present(alert, animated: true)
    }

    func finishedDeleting(_ remainingClients: [UserClient]) {
        clients = remainingClients

        editingList = false
    }

    func failedToDeleteClients(_: Error) {
        // no-op
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        if selfClient != nil, !sortedClients.isEmpty {
            2
        } else {
            1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch convertSection(section) {
        case 0:
            if selfClient != nil {
                1
            } else {
                0
            }

        case 1:
            sortedClients.count

        default:
            0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch convertSection(section) {
        case 0:
            if selfClient != nil {
                L10n.Localizable.Registration.Devices.currentListHeader
            } else {
                nil
            }

        case 1:
            L10n.Localizable.Registration.Devices.activeListHeader

        default:
            nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch convertSection(section) {
        case 0:
            nil
        case 1:
            L10n.Localizable.Registration.Devices.activeListSubtitle
        default:
            nil
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
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: ClientTableViewCell.zm_reuseIdentifier,
            for: indexPath
        ) as? ClientTableViewCell {
            cell.selectionStyle = .none
            cell.showDisclosureIndicator()

            switch convertSection((indexPath as NSIndexPath).section) {
            case 0:
                if let selfClient {
                    cell.viewModel = .init(userClient: selfClient, shouldSetType: false)
                    cell.wr_editable = false
                }

            case 1:
                cell.viewModel = .init(userClient: sortedClients[indexPath.row], shouldSetType: false)
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

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        switch convertSection((indexPath as NSIndexPath).section) {
        case 1:

            let userClient = sortedClients[indexPath.row]

            deleteUserClient(userClient, credentials: credentials)

        default: break
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell
        .EditingStyle {
        switch convertSection((indexPath as NSIndexPath).section) {
        case 0:
            .none
        case 1:
            sortedClients[indexPath.row].type == .legalHold ? .none : .delete
        default:
            .none
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !detailedView {
            return
        }

        switch convertSection((indexPath as NSIndexPath).section) {
        case 0:
            if let selfClient {
                openDetailsOfClient(selfClient)
            }

        case 1:
            openDetailsOfClient(sortedClients[indexPath.row])

        default:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        topSeparator.scrollViewDidScroll(scrollView: scrollView)
    }

    func createRightBarButtonItem() {
        if editingList {
            let doneButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
                title: L10n.Localizable.General.done,
                action: UIAction { [weak self] _ in
                    self?.editingList = false
                }
            )
            navigationItem.rightBarButtonItem = doneButtonItem
        } else {
            let editButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
                title: L10n.Localizable.General.edit,
                action: UIAction { [weak self] _ in
                    self?.editingList = true
                }
            )

            navigationItem.rightBarButtonItem = editButtonItem
        }
    }

    @MainActor
    func refreshViews() {
        clientsTableView?.reloadData()
    }

    // MARK: Private

    private var clientsTableView: UITableView?
    private let topSeparator = OverflowSeparatorView()
    private weak var delegate: ClientListViewControllerDelegate?

    private let clientSorter: (UserClient, UserClient) -> Bool
    private let clientFilter: (UserClient) -> Bool
    private let userSession: UserSession?
    private let contextProvider: ContextProvider?
    private weak var selectedDeviceInfoViewModel: DeviceInfoViewModel? // Details View

    private var sortedClients: [UserClient] = []

    private var selfClient: UserClient?
    private let detailedView: Bool
    private var credentials: UserEmailCredentials?
    private var clientsObserverToken: NSObjectProtocol?
    private var userObserverToken: NSObjectProtocol?

    private var editingList = false {
        didSet {
            guard !clients.isEmpty else {
                navigationItem.rightBarButtonItem = nil
                navigationItem.setHidesBackButton(false, animated: true)
                return
            }

            createRightBarButtonItem()

            navigationItem.setHidesBackButton(editingList, animated: true)

            clientsTableView?.setEditing(editingList, animated: true)
        }
    }

    private var clients: [UserClient] = [] {
        didSet {
            sortedClients = clients.filter(clientFilter).sorted(by: clientSorter)
            clientsTableView?.reloadData()

            if !clients.isEmpty {
                createRightBarButtonItem()
            } else {
                editingList = false
            }
        }
    }

    private func initalizeProperties(_ clientsList: [UserClient]) {
        clients = clientsList.filter { !$0.isSelfClient() }
        editingList = false
    }

    private func dismissLoadingView() {
        activityIndicator.stop()
    }

    private func makeDeviceInfoViewModel(
        client: UserClient,
        userSession: UserSession,
        contextProvider: ContextProvider
    ) -> DeviceInfoViewModel {
        let saveFileManager = SaveFileManager(systemFileSavePresenter: SystemSavePresenter())
        let deviceActionsHandler = DeviceDetailsViewActionsHandler(
            userClient: client,
            userSession: userSession,
            credentials: credentials,
            saveFileManager: saveFileManager,
            getProteusFingerprint: userSession.getUserClientFingerprint,
            contextProvider: contextProvider,
            e2eiCertificateEnrollment: userSession.enrollE2EICertificate
        )
        return DeviceInfoViewModel(
            title: client.isLegalHoldDevice ? L10n.Localizable.Device.Class.legalhold : (client.model ?? ""),
            addedDate: client.activationDate?.formattedDate ?? "",
            proteusID: client.proteusSessionID?.clientID.uppercased().splitStringIntoLines(charactersPerLine: 16) ?? "",
            userClient: client,
            isSelfClient: client.isSelfClient(),
            gracePeriod: TimeInterval(userSession.e2eiFeature.config.verificationExpiration),
            mlsCiphersuite: MLSCipherSuite(rawValue: userSession.mlsFeature.config.defaultCipherSuite.rawValue),
            isFromConversation: false,
            actionsHandler: deviceActionsHandler,
            conversationClientDetailsActions: deviceActionsHandler
        )
    }

    private func createTableView() {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.register(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.isEditing = editingList
        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        clientsTableView = tableView
    }

    private func createConstraints() {
        guard let clientsTableView else {
            return
        }

        clientsTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            clientsTableView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            clientsTableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            clientsTableView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            clientsTableView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
        ])
    }

    private func convertSection(_ section: Int) -> Int {
        if selfClient != nil {
            section
        } else {
            section + 1
        }
    }

    @MainActor
    private func updateCertificates(for userClients: [UserClient]) async {
        guard
            let userSession,
            let selfMlsGroupID = await userSession.fetchSelfConversationMLSGroupID(),
            // dangerous access: ZMUserSession.e2eiFeature initialises a FeatureRepository using the viewContext, thus
            // the following line must be executed o the main thread
            userSession.e2eiFeature.isEnabled
        else {
            return
        }

        let mlsClients: [UserClient: MLSClientID] = Dictionary(
            uniqueKeysWithValues:
            userClients
                .filter { !$0.mlsPublicKeys.allKeys.isEmpty }
                .compactMap {
                    if let mlsClientId = MLSClientID(userClient: $0) {
                        ($0, mlsClientId)
                    } else {
                        nil
                    }
                }
        )

        do {
            let certificates = try await userSession.getE2eIdentityCertificates.invoke(
                mlsGroupId: selfMlsGroupID,
                clientIds: Array(mlsClients.values)
            )

            for (client, mlsClientId) in mlsClients {
                if let e2eiCertificate = certificates.first(where: { $0.clientId == mlsClientId.rawValue }) {
                    client.e2eIdentityCertificate = e2eiCertificate
                }
                client.mlsThumbPrint = client.e2eIdentityCertificate?.mlsThumbprint
            }

        } catch {
            WireLogger.e2ei.error(String(reflecting: error))
        }
    }

    private func updateAllClients(completed: (() -> Void)? = nil) {
        guard let selfUser = ZMUser.selfUser(), selfUser.selfClient() != nil else {
            completed?()
            return
        }
        Task {
            await updateCertificates(for: Array(selfUser.clients))
            refreshViews()
            completed?()
        }
    }

    private func updateE2EIdentityCertificateInDetailsView() {
        guard let client = findE2EIdentityCertificateClient() else {
            return
        }
        selectedDeviceInfoViewModel?.update(from: client)
    }

    private func findE2EIdentityCertificateClient() -> UserClient? {
        if selectedDeviceInfoViewModel?.isSelfClient == true {
            return selfClient
        }

        guard let selectedUserClient = selectedDeviceInfoViewModel?.userClient as? UserClient else {
            return nil
        }

        return clients.first { $0.clientId == selectedUserClient.clientId }
    }
}

// MARK: EditingStateControllable

extension ClientListViewController: EditingStateControllable {
    /// Sets the editing state of the ClientListViewController.
    /// This method is primarily used for testing purposes to directly
    /// control the editing state without user interaction.
    ///
    /// - Parameter isEditing: A boolean indicating whether to enter (true) or exit (false) editing mode.
    func setEditingState(_ isEditing: Bool) {
        editingList = isEditing
    }
}

// MARK: ClientRemovalObserverDelegate

extension ClientListViewController: ClientRemovalObserverDelegate {
    func setIsLoadingViewVisible(_ clientRemovalObserver: ClientRemovalObserver, isVisible: Bool) {
        guard removalObserver == clientRemovalObserver else {
            return
        }

        activityIndicator.setIsActive(isVisible)
    }

    func present(_ clientRemovalObserver: ClientRemovalObserver, viewControllerToPresent: UIViewController) {
        guard removalObserver == clientRemovalObserver else {
            return
        }

        present(viewControllerToPresent, animated: true)
    }
}

// MARK: UserObserving

extension ClientListViewController: UserObserving {
    func userDidChange(_ note: UserChangeInfo) {
        if note.clientsChanged || note.trustLevelChanged {
            updateAllClients()
        }
    }
}
