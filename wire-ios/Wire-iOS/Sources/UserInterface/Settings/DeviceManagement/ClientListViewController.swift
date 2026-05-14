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

import SwiftUI
import WireCommonComponents
import WireDesign
import WireLogging
import WireMainNavigationUI
import WireReusableUIComponents
import WireSettingsUI
import WireSyncEngine

private let zmLog = ZMSLog(tag: "UI")

struct SelfClientListViewControllerBuilder {

    private let userSession: UserSession
    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    init(
        userSession: UserSession,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.userSession = userSession
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    @MainActor
    func build(clientsList: [UserClient]) -> ClientListViewController {
        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation(clientsList: clientsList)
        }

        return buildLegacy(clientsList: clientsList)
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .selfClientList,
            isKMPImplementationAvailable: false
        )
    }

    @MainActor
    private func buildKMPViewModelImplementation(clientsList: [UserClient]) -> ClientListViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy(clientsList: clientsList)
    }

    @MainActor
    private func buildLegacy(clientsList: [UserClient]) -> ClientListViewController {
        ClientListViewController(
            clientsList: clientsList,
            selfClient: userSession.selfUserClient,
            userSession: userSession,
            credentials: nil,
            contextProvider: userSession.contextProvider,
            detailedView: true,
            showTemporary: true
        )
    }
}

final class ClientListViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    ClientUpdateObserver,
    ClientColorVariantProtocol {

    // MARK: SpinnerCapable

    var removalObserver: ClientRemovalObserver?

    private var clientsTableView: UITableView?
    private let topSeparator = OverflowSeparatorView()
    private weak var delegate: ClientListViewControllerDelegate?

    private var editingList: Bool {
        viewModel.isEditing
    }

    private let viewModel: ClientListViewModel

    private func setEditingList(_ isEditing: Bool) {
        viewModel.setEditing(isEditing)

        guard viewModel.showsEditButton else {
            navigationItem.rightBarButtonItem = nil
            navigationItem.setHidesBackButton(false, animated: true)
            clientsTableView?.setEditing(false, animated: true)
            return
        }

        createRightBarButtonItem()

        navigationItem.setHidesBackButton(viewModel.hidesBackButton, animated: true)

        clientsTableView?.setEditing(viewModel.isEditing, animated: true)
    }

    private func updateClients(_ clientsList: [UserClient]) {
        viewModel.updateClients(clientsList)
        clientsTableView?.reloadData()

        if viewModel.showsEditButton {
            createRightBarButtonItem()
        } else {
            setEditingList(false)
        }
    }

    private let userSession: UserSession
    private let contextProvider: ContextProvider?
    private weak var selectedDeviceInfoViewModel: DeviceInfoViewModel? // Details View

    private var credentials: UserEmailCredentials?
    private var clientsObserverToken: NSObjectProtocol?
    private var userObserverToken: NSObjectProtocol?

    private(set) lazy var activityIndicator = BlockingActivityIndicator(view: navigationController?.view ?? view)

    required init(
        clientsList: [UserClient]?,
        selfClient: UserClient?,
        userSession: UserSession,
        credentials: UserEmailCredentials? = .none,
        contextProvider: ContextProvider?,
        detailedView: Bool = false,
        showTemporary: Bool = true,
        showLegalHold: Bool = true
    ) {
        self.userSession = userSession
        self.credentials = credentials
        self.contextProvider = contextProvider
        self.viewModel = ClientListViewModel(
            clientsList: clientsList ?? Array(ZMUser.selfUser()?.clients.filter { !$0.isSelfClient() } ?? []),
            selfClient: selfClient,
            showTemporary: showTemporary,
            showLegalHold: showLegalHold,
            showsDeviceDetails: detailedView
        )

        super.init(nibName: nil, bundle: nil)

        self.clientsObserverToken = (userSession as? ZMUserSession)?.addClientUpdateObserver(self)
        if let user = ZMUser.selfUser(), let session = userSession as? ZMUserSession {
            self.userObserverToken = UserChangeInfo.add(observer: self, for: user, in: session)
        }

        if viewModel.activeClients.isEmpty {
            activityIndicator.start()
            userSession.fetchAllClients()
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createTableView()
        setEditingList(viewModel.isEditing)
        view.addSubview(topSeparator)
        createConstraints()

        navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.ClientsList.BackButton.description
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

        // Prevent more then one removalObserver in self and SettingsClientViewController
        removalObserver = nil
    }

    private func dismissLoadingView() async {
        let minimumDelay: TimeInterval = 0.2
        let nanoseconds = UInt64(minimumDelay * 1_000_000_000)

        try? await Task.sleep(nanoseconds: nanoseconds)
        await MainActor.run {
            activityIndicator.stop()
        }
    }

    func openDetailsOfClient(_ client: UserClient) {
        guard let contextProvider,
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
            successEnrollmentViewController.presentOverAll()
        }
        selectedDeviceInfoViewModel = viewModel

        let detailsViewController = DeviceInfoViewController(rootView: DeviceDetailsView(viewModel: viewModel))
        navigationController.pushViewController(detailsViewController, animated: true)
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
            clientsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            clientsTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            clientsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            clientsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc
    func backPressed(_ sender: AnyObject!) {
        navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func deleteUserClient(
        _ userClient: UserClient,
        credentials: UserEmailCredentials?
    ) {
        removalObserver = ClientRemovalObserver(
            userClientToDelete: userClient,
            delegate: self,
            userSession: userSession,
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
                updateClients(userClients)
            }
            await dismissLoadingView()
        }
    }

    func failedToFetchClients(_ error: Error) {
        Task {
            await dismissLoadingView()
        }

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
        updateClients(remainingClients)
        setEditingList(false)
    }

    func failedToDeleteClients(_ error: Error) {
        // no-op
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.headerTitle(for: section)
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        viewModel.footerTitle(for: section)
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
            cell.showDisclosureIndicatorAccessoryView()

            if let rowModel = viewModel.rowModel(at: indexPath) {
                cell.viewModel = rowModel.cellViewModel
                cell.wr_editable = rowModel.isEditable
            } else {
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
        switch viewModel.actionForDeletingRow(at: indexPath) {
        case let .delete(userClient):
            deleteUserClient(userClient, credentials: credentials)
        case .none:
            break
        }

    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell
        .EditingStyle {
        viewModel.rowModel(at: indexPath)?.canDelete == true ? .delete : .none

    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.routeForSelectingRow(at: indexPath) {
        case let .deviceDetails(client):
            openDetailsOfClient(client)
        case .none:
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
                    self?.setEditingList(false)
                }
            )
            navigationItem.rightBarButtonItem = doneButtonItem
        } else {
            let editButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
                title: L10n.Localizable.General.edit,
                action: UIAction { [weak self] _ in
                    self?.setEditingList(true)
                }
            )

            navigationItem.rightBarButtonItem = editButtonItem
        }
    }

    @MainActor
    private func updateCertificates(for userClients: [UserClient]) async {
        activityIndicator.start()
        guard
            let selfMlsGroupID = await userSession.fetchSelfConversationMLSGroupID()
        else {
            activityIndicator.stop()
            return
        }

        let mlsClients: [UserClient: MLSClientID] = Dictionary(
            uniqueKeysWithValues:
            userClients
                .filter { !$0.mlsPublicKeys.allKeys.isEmpty }
                .compactMap {
                    if let mlsClientId = MLSClientID(
                        userClient: $0,
                        localDomain: userSession.resolvedBackendMetadata.domain
                    ) {
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
                    if userSession.e2eiFeature.isEnabled {
                        client.e2eIdentityCertificate = e2eiCertificate
                    }
                    client.mlsThumbPrint = e2eiCertificate.mlsThumbprint
                }
            }
        } catch {
            WireLogger.e2ei.error(String(reflecting: error))
        }
        await dismissLoadingView()
    }

    private func updateAllClients(completed: (() -> Void)? = nil) {
        guard let selfUser = ZMUser.selfUser(), selfUser.selfClient() != nil else {
            completed?()
            return
        }
        Task {
            let clients = Array(selfUser.clients)
            await updateCertificates(for: clients)
            await MainActor.run {
                updateClients(clients)
                completed?()
            }
        }
    }

    @MainActor
    func refreshViews() {
        clientsTableView?.reloadData()
    }

    private func updateE2EIdentityCertificateInDetailsView() {
        guard let client = findE2EIdentityCertificateClient() else { return }
        selectedDeviceInfoViewModel?.update(from: client)
    }

    private func findE2EIdentityCertificateClient() -> UserClient? {
        viewModel.clientForUpdatedDetails(
            selectedClient: selectedDeviceInfoViewModel?.userClient as? UserClient,
            selectedClientIsSelfClient: selectedDeviceInfoViewModel?.isSelfClient == true
        )
    }
}

extension ClientListViewController: EditingStateControllable {

    /// Sets the editing state of the ClientListViewController.
    /// This method is primarily used for testing purposes to directly
    /// control the editing state without user interaction.
    ///
    /// - Parameter isEditing: A boolean indicating whether to enter (true) or exit (false) editing mode.
    func setEditingState(_ isEditing: Bool) {
        setEditingList(isEditing)
    }

}

// MARK: - ClientRemovalObserverDelegate

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

extension ClientListViewController: UserObserving {

    func userDidChange(_ note: UserChangeInfo) {
        if note.clientsChanged || note.trustLevelChanged {
            updateAllClients()
        }
    }

}
