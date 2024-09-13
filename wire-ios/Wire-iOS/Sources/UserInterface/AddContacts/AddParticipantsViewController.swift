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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

extension ConversationLike where Self: SwiftConversationLike {
    var canAddGuest: Bool {
        // If not a team conversation: possible to add any contact.
        guard teamType != nil else {
            return true
        }

        // Access mode and/or role is unknown: let's try to add and observe the result.
        guard let accessMode else {
            return true
        }

        let canAddGuest = accessMode.contains(.invite)
        let guestCanBeAdded = accessRoles.contains(.nonTeamMember) && accessRoles.contains(.guest)

        return canAddGuest && guestCanBeAdded
    }
}

protocol AddParticipantsConversationCreationDelegate: AnyObject {
    func addParticipantsViewController(
        _ addParticipantsViewController: AddParticipantsViewController,
        didPerform action: AddParticipantsViewController.CreateAction
    )
}

extension AddParticipantsViewController.Context {
    var includeGuests: Bool {
        switch self {
        case let .add(conversation):
            conversation.canAddGuest
        case let .create(creationValues):
            creationValues.allowGuests
        }
    }

    var selectionLimit: Int {
        switch self {
        case let .add(conversation):
            conversation.freeParticipantSlots
        case .create:
            ZMConversation.maxParticipantsExcludingSelf
        }
    }

    var alertForSelectionOverflow: UIAlertController {
        typealias AddParticipantsAlert = L10n.Localizable.AddParticipants.Alert
        let max = ZMConversation.maxParticipants
        let message: String
        switch self {
        case let .add(conversation):
            let freeSpace = conversation.freeParticipantSlots
            message = AddParticipantsAlert.Message.existingConversation(max, freeSpace)
        case .create:
            message = AddParticipantsAlert.Message.newConversation(max)
        }

        let controller = UIAlertController(
            title: AddParticipantsAlert.title.capitalized,
            message: message,
            preferredStyle: .alert
        )

        controller.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default
        ))
        return controller
    }
}

final class AddParticipantsViewController: UIViewController {
    enum CreateAction {
        case updatedUsers(UserSet)
        case create
    }

    enum Context {
        case add(GroupDetailsConversationType)
        case create(ConversationCreationValues)
    }

    private let userSession: UserSession

    private let searchResultsViewController: SearchResultsViewController
    private let searchGroupSelector: SearchGroupSelector
    private let searchHeaderViewController: SearchHeaderViewController
    let userSelection = UserSelection()
    private let collectionView: UICollectionView
    private let collectionViewLayout: UICollectionViewFlowLayout
    private let confirmButtonHeight: CGFloat = 56.0
    private let confirmButton: IconButton
    private let emptyResultView: EmptySearchResultsView
    private lazy var bottomConstraint: NSLayoutConstraint = confirmButton.bottomAnchor.constraint(
        equalTo: view.bottomAnchor,
        constant: -bottomMargin
    )
    private let backButtonDescriptor = BackButtonDescription()
    private let bottomMargin: CGFloat = 24

    weak var conversationCreationDelegate: AddParticipantsConversationCreationDelegate?

    private var activityIndicator: BlockingActivityIndicator!

    private var viewModel: AddParticipantsViewModel {
        didSet {
            updateValues()
        }
    }

    deinit {
        userSelection.remove(observer: self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(
        conversation: GroupDetailsConversationType,
        userSession: UserSession
    ) {
        self.init(
            context: .add(conversation),
            userSession: userSession
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator = .init(view: view)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _ = searchHeaderViewController.tokenField.resignFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateTitle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    init(
        isFederationEnabled: Bool = BackendInfo.isFederationEnabled,
        context: Context,
        userSession: UserSession
    ) {
        self.userSession = userSession

        self.viewModel = AddParticipantsViewModel(with: context)

        self.collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0

        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.allowsMultipleSelection = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true

        self.confirmButton = IconButton(fontSpec: .normalSemiboldFont)
        confirmButton.applyStyle(.addParticipantsDisabledButtonStyle)
        confirmButton.setBackgroundImageColor(SemanticColors.Button.backgroundPrimaryDisabled, for: .disabled)
        confirmButton.contentHorizontalAlignment = .center
        confirmButton.setTitleImageSpacing(16, horizontalMargin: 24)
        confirmButton.layer.cornerRadius = 16
        confirmButton.layer.masksToBounds = true

        self.searchHeaderViewController = SearchHeaderViewController(userSelection: userSelection)

        self.searchGroupSelector = SearchGroupSelector()

        self.searchResultsViewController = SearchResultsViewController(
            userSelection: userSelection,
            userSession: userSession,
            isAddingParticipants: true,
            shouldIncludeGuests: viewModel.context.includeGuests,
            isFederationEnabled: isFederationEnabled
        )

        let user = SelfUser.provider?.providedSelfUser
        self.emptyResultView = EmptySearchResultsView(
            isSelfUserAdmin: user?.canManageTeam == true,
            isFederationEnabled: isFederationEnabled
        )
        super.init(nibName: nil, bundle: nil)

        emptyResultView.delegate = self

        userSelection.setLimit(context.selectionLimit) {
            self.present(context.alertForSelectionOverflow, animated: true)
        }

        updateValues()

        confirmButton.addTarget(
            self,
            action: #selector(searchHeaderViewControllerDidConfirmAction(_:)),
            for: .touchUpInside
        )

        searchResultsViewController.filterConversation = viewModel.filterConversation
        searchResultsViewController.mode = .list
        searchResultsViewController.searchContactList()
        searchResultsViewController.delegate = self

        userSelection.add(observer: self)

        searchGroupSelector.onGroupSelected = { [weak self] group in
            guard let self else {
                return
            }
            // Remove selected users when switching to services tab to avoid the user confusion: users in the field are
            // not going to be added to the new conversation with the bot.
            if group == .services {
                searchHeaderViewController.clearInput()
                confirmButton.isHidden = true
            } else {
                confirmButton.isHidden = false
            }

            searchResultsViewController.searchGroup = group
            performSearch()
        }

        viewModel.selectedUsers.forEach(userSelection.add)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        if viewModel.botCanBeAdded {
            view.addSubview(searchGroupSelector)
        }

        searchHeaderViewController.delegate = self
        addChild(searchHeaderViewController)
        view.addSubview(searchHeaderViewController.view)
        searchHeaderViewController.didMove(toParent: self)

        addChild(searchResultsViewController)
        view.addSubview(searchResultsViewController.view)
        searchResultsViewController.didMove(toParent: self)
        searchResultsViewController.searchResultsView.emptyResultView = emptyResultView
        searchResultsViewController.searchResultsView.backgroundColor = SemanticColors.View.backgroundDefault
        searchResultsViewController.searchResultsView.collectionView.accessibilityIdentifier = "add_participants.list"

        view.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(confirmButton)

        createConstraints()
        updateSelectionValues()

        if searchResultsViewController.isResultEmpty {
            emptyResultView.updateStatus(searchingForServices: false, hasFilter: false)
        }
    }

    private func createConstraints() {
        let searchMargin: CGFloat = confirmButton.isHidden ? 0 : (confirmButtonHeight + bottomMargin * 2)
        guard let searchHeaderView = searchHeaderViewController.view,
              let searchResultsView = searchResultsViewController.view,
              let margin = (searchResultsView as? SearchResultsView)?.accessoryViewMargin else {
            return
        }

        [
            searchHeaderView,
            searchResultsView,
            confirmButton,
            searchGroupSelector,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        var constraints: [NSLayoutConstraint] = [
            searchHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            searchHeaderView.leftAnchor.constraint(equalTo: view.leftAnchor),
            searchHeaderView.rightAnchor.constraint(equalTo: view.rightAnchor),

            searchResultsView.leftAnchor.constraint(equalTo: view.leftAnchor),
            searchResultsView.rightAnchor.constraint(equalTo: view.rightAnchor),
            searchResultsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -searchMargin),

            confirmButton.heightAnchor.constraint(equalToConstant: confirmButtonHeight),
            confirmButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin),
            confirmButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin),
            bottomConstraint,
        ]

        if viewModel.botCanBeAdded {
            constraints.append(contentsOf: [
                searchGroupSelector.topAnchor.constraint(equalTo: searchHeaderView.bottomAnchor),
                searchGroupSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                searchGroupSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                searchResultsView.topAnchor.constraint(equalTo: searchGroupSelector.bottomAnchor),
            ])
        } else {
            constraints.append(
                searchResultsView.topAnchor.constraint(equalTo: searchHeaderView.bottomAnchor)
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func updateValues() {
        if let buttonTitle = viewModel.confirmButtonTitle {
            confirmButton.isHidden = false
            confirmButton.setTitle(buttonTitle, for: .normal)
        } else {
            confirmButton.isHidden = true
        }
        updateTitle()
        navigationItem.rightBarButtonItem = viewModel.rightNavigationItem(action: rightNavigationItemTapped())
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.AddParticipantsConversationSettings
            .CloseButton.description
    }

    private func updateSelectionValues() {
        // Update view model after selection changed
        if case let .create(values) = viewModel.context {
            let mlsFeature = userSession.makeGetMLSFeatureUseCase().invoke()
            let updated = ConversationCreationValues(
                name: values.name,
                participants: userSelection.users,
                allowGuests: true,
                allowServices: true,
                encryptionProtocol: mlsFeature.config.defaultProtocol,
                selfUser: userSession.selfUser
            )
            viewModel = AddParticipantsViewModel(with: .create(updated))
        }

        // Enable button & collection view content inset
        updateConfirmButtonState(state: !userSelection.users.isEmpty)

        updateTitle()

        // Notify delegate
        conversationCreationDelegate?.addParticipantsViewController(
            self,
            didPerform: .updatedUsers(userSelection.users)
        )
    }

    private func updateConfirmButtonState(state: Bool) {
        confirmButton.isEnabled = state
        confirmButton.applyStyle(state ? .addParticipantsButtonStyle : .addParticipantsDisabledButtonStyle)
    }

    private func updateTitle() {
        title = switch viewModel.context {
        case let .create(values): viewModel.title(with: values.participants)
        case .add: viewModel.title(with: userSelection.users)
        }

        guard let title else { return }

        setupNavigationBarTitle(title.capitalized)
    }

    private func rightNavigationItemTapped() -> UIAction {
        UIAction { [weak self] _ in
            guard let self else { return }

            switch viewModel.context {
            case .add:
                navigationController?.dismiss(animated: true, completion: nil)
            case .create:
                conversationCreationDelegate?.addParticipantsViewController(self, didPerform: .create)
            }
        }
    }

    func setLoadingView(isVisible: Bool) {
        activityIndicator.setIsActive(isVisible)
        navigationItem.rightBarButtonItem?.isEnabled = !isVisible
    }

    @objc
    func keyboardFrameWillChange(notification: Notification) {
        // Don't adjust the frame when being presented in a popover.
        if let arrowDirection = popoverPresentationController?.arrowDirection, arrowDirection == .unknown {
            return
        }

        let firstResponder = UIResponder.currentFirst
        let inputAccessoryHeight = firstResponder?.inputAccessoryView?.bounds.size.height ?? 0

        UIView.animate(
            withKeyboardNotification: notification,
            in: view,
            animations: { [weak self] keyboardFrameInView in
                guard let self else { return }

                let keyboardHeight = keyboardFrameInView.size.height - inputAccessoryHeight

                bottomConstraint.constant = -(keyboardHeight + bottomMargin)
                view.layoutIfNeeded()
            }
        )
    }

    private func performSearch() {
        let searchingForServices = searchResultsViewController.searchGroup == .services
        let hasFilter = !searchHeaderViewController.tokenField.filterText.isEmpty

        emptyResultView.updateStatus(searchingForServices: searchingForServices, hasFilter: hasFilter)

        switch (searchResultsViewController.searchGroup, hasFilter) {
        case (.services, _):
            searchResultsViewController.mode = .search
            searchResultsViewController.searchForServices(withQuery: searchHeaderViewController.tokenField.filterText)
        case (.people, false):
            searchResultsViewController.mode = .list
            searchResultsViewController.searchContactList()
        case (.people, true):
            searchResultsViewController.mode = .search
            searchResultsViewController.searchForLocalUsers(withQuery: searchHeaderViewController.tokenField.filterText)
        }
    }

    private func addSelectedParticipants(to conversation: GroupDetailsConversationType) {
        let selectedUsers = userSelection.users

        (conversation as? ZMConversation)?.addOrShowError(participants: Array(selectedUsers))
    }
}

extension AddParticipantsViewController: UserSelectionObserver {
    func userSelection(_ userSelection: UserSelection, didAddUser user: UserType) {
        updateSelectionValues()
    }

    func userSelection(_ userSelection: UserSelection, didRemoveUser user: UserType) {
        updateSelectionValues()
    }

    func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [UserType]) {
        updateSelectionValues()
    }
}

extension AddParticipantsViewController: SearchHeaderViewControllerDelegate {
    @objc
    func searchHeaderViewControllerDidConfirmAction(_: SearchHeaderViewController) {
        if case let .add(conversation) = viewModel.context {
            dismiss(animated: true) {
                self.addSelectedParticipants(to: conversation)
            }
        }
    }

    func searchHeaderViewController(
        _ searchHeaderViewController: SearchHeaderViewController,
        updatedSearchQuery query: String
    ) {
        performSearch()
    }
}

extension AddParticipantsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        UIModalPresentationStyle.overFullScreen
    }

    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        UIModalPresentationStyle.overFullScreen
    }
}

extension AddParticipantsViewController: SearchResultsViewControllerDelegate {
    func searchResultsViewController(
        _ searchResultsViewController: SearchResultsViewController,
        didTapOnUser user: UserType,
        indexPath: IndexPath,
        section: SearchResultsViewControllerSection
    ) {
        // no-op
    }

    func searchResultsViewController(
        _ searchResultsViewController: SearchResultsViewController,
        didDoubleTapOnUser user: UserType,
        indexPath: IndexPath
    ) {
        // no-op
    }

    func searchResultsViewController(
        _ searchResultsViewController: SearchResultsViewController,
        didTapOnConversation conversation: ZMConversation
    ) {
        // no-op
    }

    func searchResultsViewController(
        _ searchResultsViewController: SearchResultsViewController,
        wantsToPerformAction action: SearchResultsViewControllerAction
    ) {
        // no-op
    }

    func searchResultsViewController(
        _ searchResultsViewController: SearchResultsViewController,
        didTapOnSeviceUser user: ServiceUser
    ) {
        guard case let .add(conversation) = viewModel.context else { return }

        let detail = ServiceDetailViewController(
            serviceUser: user,
            actionType: .addService(conversation as! ZMConversation),
            userSession: userSession
        ) { [weak self] result in
            guard let self, let result else { return }
            switch result {
            case .success:
                dismiss(animated: true)
            case let .failure(error):
                guard let controller = navigationController?.topViewController else { return }
                error.displayAddBotError(in: controller)
            }
        }

        navigationController?.pushViewController(detail, animated: true)
    }
}

extension AddParticipantsViewController: EmptySearchResultsViewDelegate {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView) {
        switch action {
        case .openManageServices:
            URL.manageTeam(source: .onboarding).openInApp(above: self)
        case .openSearchSupportPage:
            WireURLs.shared.searchSupport.open()
        }
    }
}
